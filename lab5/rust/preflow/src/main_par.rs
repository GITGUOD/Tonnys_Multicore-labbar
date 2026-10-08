#[macro_use] extern crate text_io; // importing a crate, a library which in this case text_io, which is used for reading input from stdin. It's like import text_io
// #[macro_use] is basically attribute that allows us to use macros from the text_io crate without having to prefix them with the crate name. In this case, it allows us to use the read! macro directly.
// macro is a way to define reusable code snippets that can be expanded at compile time. In this case, the read! macro is used to read input from stdin and parse it into the specified type.
// Without #[macro_use], we would have to write text_io::read! instead of just read!. This is a convenience feature that makes the code cleaner and easier to read.
use std::sync::{Mutex, Barrier, RwLock}; // use statements for importing the Mutex and Arc types from the std::sync module. Arc is a thread-safe reference-counting pointer that allows multiple threads to share ownership of the same data. Mutex is a mutual exclusion primitive that allows only one thread to access the data at a time, preventing data races.
use std::collections::LinkedList;
use std::thread;
use std::time::Instant; 

// RUst documentation: https://doc.rust-lang.org/beta/std/sync/struct.Barrier.html

const N: usize = 4; // number of threads

struct Node { // struct is like a class in other programming languages. It is used to define a custom data type that can hold multiple values of different types. In this case, the Node struct is used to represent a node in a graph, with fields for its index, excess preflow, and height.
	i:	usize,			/* index of itself for debugging.	*/
	e:	i32,			/* excess preflow.			*/
	h:	i32,			/* height.				*/
}

struct Edge {
        u:      usize,  // use usize for the index of the source node of the edge. This is used to identify the starting point of the edge in the graph.
        v:      usize, 
        f:      i32, // use i32 for the flow of the edge. This is used to represent the amount of flow that is currently passing through the edge in the graph.
        c:      i32,
}
// i32 is a 32-bit signed integer type in Rust. It can represent values from -2,147,483,648 to 2,147,483,647. In this code, i32 is used for the flow and capacity of the edges because these values can be negative (for flow) and can be large enough to require a 32-bit integer.
// usize is an unsigned integer type in Rust that is used for indexing and sizing. It is guaranteed to be able to hold any value that can be represented by a pointer on the target architecture. In this code, usize is used for the indices of nodes and edges because they are used for indexing into arrays and vectors, which require non-negative values.

impl Node { // impl is short for implementation. It is used to define methods and associated functions for a struct. In this case, the impl block is used to define a constructor function for the Node struct.
	fn new(ii:usize) -> Node { //constructor
		Node {
			i: ii, // index of itself for debugging. This is used to identify the node in the graph and can be useful for debugging purposes.
			e: 0,
			h: 0
		}
	}

}
// Vi måste ange manuellt hur kompilatorn ska tolka decision structen.
// Copy -> kopiera instansen/
// Clone -> skapa en ny instans med samma värden som den gamla.
// Default -> skapa en ny instans/tom med default värden.
// https://doc.rust-lang.org/rust-by-example/trait/derive.html
#[derive(Clone, Copy, Default)]
struct Decision {
	sender: usize,
	receiver: usize,
	edge_index: usize,
	amount: i32,
	is_relabel: bool,
}


impl Edge {
        fn new(uu:usize, vv:usize,cc:i32) -> Edge { //constructor
                Edge {
					u: uu,
					v: vv,
					f: 0,
					c: cc
				}      
        }
}

/* Graph struct
	- Våran graf består av:
		- Noder
		- Kanter
		- Adjacenslista (LinkedList<usize>) som innehåller indexen för kanterna som är kopplade till varje nod.
		- Workload som innehåller indexen för noderna som har excess preflow och behöver bearbetas, vi hade bara excess i våran vanliga sequential implementation, men nu behöver vi en workload för att kunna parallellisera arbetet
		- NextWorkload som innehåller indexen för noderna som har excess preflow och behöver bearbetas i nästa runda.
		- queued_this_round som är en vektor av booleska värden som används för att hålla reda på vilka noder som redan har lagts till i nextWorkload under den aktuella rundan. Detta förhindrar att samma nod läggs till flera gånger i nextWorkload.
*/
struct Graph {
	nodes: Vec<Node>,
	edges: Vec<Edge>,
	adj: Vec<LinkedList<usize>>,
	currentWorkload: Vec<usize>,
	nextWorkload: Vec<usize>,
	queued_this_round: Vec<bool>,
}
	
impl Graph {

	// Konstruktorn
	fn new(u: Vec<Node>, e: Vec<Edge>, a: Vec<LinkedList<usize>>) -> Graph {
		let n = u.len(); // När vi skapar en graf, så vill vi veta hur många noder vi har, så vi kan skapa en vektor av booleska värden som håller reda på vilka noder som redan har lagts till i nextWorkload under den aktuella rundan. Detta förhindrar att samma nod läggs till flera gånger i nextWorkload.
		Graph {
			nodes: u, // Antalet noder i grafen, som vi får från vektorn u som vi skickar in i konstruktorn.
			edges: e, // .. kanter
			adj: a, // Adjacenslistan som vi får från vektorn a som vi skickar in i konstruktorn.
			currentWorkload: Vec::with_capacity(n), // Workload som innehåller indexen för noderna som har excess preflow och behöver bearbetas, vi hade bara excess i våran vanliga sequential implementation, men nu behöver vi en workload för att kunna parallellisera arbetet
			nextWorkload: Vec::with_capacity(n), // osv
			queued_this_round: vec![false; n],
		}
	}

	// källan
	fn source(&self) -> usize {
		0
	}

	// sänkan
	fn sink(&self) -> usize {
		self.nodes.len() - 1
	}

	// lägger till en kant i grafen
	fn add_edge(&mut self, u: usize, v: usize, c: i32) {
		let index = self.edges.len(); // index of den nya eftersom vi lägger till en ny
		self.edges.push(Edge::new(u, v, c)); // lägger till en ny kant i grafen
		self.adj[u].push_back(index); // lägger till indexet för den nya kanten i adjacenslistan för noden u, push_back() lägger till elementet i slutet av listan, så att vi kan iterera över alla kanter som är kopplade till noden u.
		self.adj[v].push_back(index); // samma v eftersom kanten består av två noder, u och v, och vi vill kunna iterera över alla kanter som är kopplade till dom noderna och därför måste de ha samma index i adjacenslistan
	}

	// Samma som other i C-koden, returnerar den andra noden i kanten e som inte är u. Om u är källan för kanten, returnerar den målet, annars returnerar den källan.
	fn other(&self, u: usize, e: &Edge) -> usize {
		if u == e.u {
			e.v
		} else {
			e.u
		}
	}

	fn push_amount(&self, u: usize, edge_index: usize) -> i32 {
		// implementation of the push_amount operation
		let d: i32;	/* remaining capacity of the edge. */
		
		if u == self.edges[edge_index].u {
			d = std::cmp::min(self.nodes[u].e, self.edges[edge_index].c - self.edges[edge_index].f); // plussa eller minus beroende vilken riktning vi pushar till
		} else {
			d = std::cmp::min(self.nodes[u].e, self.edges[edge_index].c + self.edges[edge_index].f);
		}

		return d;
	}

	fn push(&mut self, u: usize, v: usize, edge_index: usize) {
		// implementation of the push operation
			
		let d = self.push_amount(u, edge_index); // bestämmer hur mycket vi kan pusha

		println!("pushing {}\n", d);

		// addera eller subtrahera beroende på vilket riktning

		if u == self.edges[edge_index].u {
			self.edges[edge_index].f += d; 
		} else {
			self.edges[edge_index].f -= d;
		}

		// Sen måste vi uppdatera excess preflow för noderna u och v. Vi subtraherar d från noden u:s excess preflow och adderar d till noden v:s excess preflow. Detta är viktigt eftersom vi har flyttat flöde från noden u till noden v, och därför måste vi uppdatera deras excess preflow för att återspegla detta.
		// Anledningen till varför vi inte ha en if sats här är för att vi redan har bestämt riktningen på flödet i push_amount() och därför vet vi att d alltid kommer att vara positivt. Vi kan därför direkt subtrahera d från noden u:s excess preflow och addera d till noden v:s excess preflow utan att behöva kontrollera riktningen igen.
		// d kan ju vara negativt vilket gör att d blir då plus för u och minus för v, men det är ju bara att vända på det, så vi behöver inte en if sats här.
		self.nodes[u].e -= d; 
		self.nodes[v].e += d;

		/* the following are always true. */

		assert!(d >= 0);
		assert!(self.nodes[u].e >= 0);
		assert!(self.edges[edge_index].f.abs() <= self.edges[edge_index].c);

	}
	// mut är en förkortning för mutable (muterbar), alltså att något får ändras.
	fn relabel(&mut self, u: usize) {
		// implementation of the relabel operation
		self.nodes[u].h += 1;
	}

	fn preflow(mut self) -> i32 {
		// implementation of the preflow operation

		let s = self.source();
		let t = self.sink();
		self.nodes[s].h = self.nodes.len() as i32;

		// LinkedList<usize> of edge indices. // Rust är strikt när det gäller att flera vill ändra mot samma referens till samma lista/object.
		// Endast read only fås göra, därför måste vi klona listan vid ändringar o så *CLONE*

		/* start by pushing as much as possible (limited by
		* the edge capacity) from the source to its neighbors.
		*
		*/
		let source_edges = self.adj[s].clone(); 
		for e in source_edges {
			let c = self.edges[e].c;
			self.nodes[s].e += c;
			let r = self.other(s, &self.edges[e]);
			self.push(s, r, e);
		}

		let n = self.nodes.len();
		// Om noderna vi inte ska jobba med är källan eller sänkan, då lägger vi i våran arbetslista
		for i in 0..n {
			if i != s && i != t && self.nodes[i].e > 0 {
				self.currentWorkload.push(i);
			}
		}

		let shared = RwLock::new(self); // När en tråd skriver får ingen annan göra det
		let barrier = Barrier::new(N); // creating a barrier that will be used to synchronize the threads. The barrier is initialized with a count of N, which is the number of threads that will be created.

		let mut decision_list = Vec::new(); // Skapa en vektor med decisions
		for _ in 0..n {
			decision_list.push(Mutex::new(Decision::default())); // initiera decisions
		}

		let shared_ref = &shared; //skapa referensinstanser
		let barrier_ref = &barrier;
		let decision_list_ref = &decision_list;
		/*Varför? Jo, En variabel i Rust kan bara ha en enda ägare. Du har bara en enda shared (RwLock).
		När du startar flera trådar vill du att alla $N$ trådar ska peka på exakt samma.
		Om du skickar shared direkt reagerar Rust med: "Jag kan inte skicka hela objektet till tråd 1 OCH tråd 2 OCH tråd 3."

		Genom att skriva let shared_ref = &shared; skapar du en namngiven adresslapp (en referensinstans). 
		Denna adresslapp går utmärkt att kopiera om och om igen till varje tråd. */

		thread::scope(|scope| { // startar trådarna, thread::scope blockerar och väntar automatiskt tills alla $N$ trådar inuti blocket har kört klart.
			for thread_id in 0..N {
				scope.spawn(move || { // move, betyder "ta ägandeskap och flytta in variablerna", move tvingar Rust att kopiera och flytta över alla variabler som används inuti kodblocket till den nya trådens privata minne: så kallade: varje tråd i datorn har sitt eget privata minnesutrymme (en egen stack) att jobba med
					create_threads(
						shared_ref,
						barrier_ref,
						decision_list_ref,
						thread_id,
					);
				});
			}
		});

		let g = shared.into_inner().unwrap(); // Återställer och hämtar datan
		/* .into_inner(): eftersom trådarna har slutat vet Rust att ingen annan längre använder trådlåset. Då "förstörs" RwLock-skalet och du får tillbaka det rena originalvärdet (din graf) utan något lås runt sig.
		.unwrap(): Packar upp värdet ur Result.
		let g = ...: g innehåller nu den slutgiltiga, uppdaterade grafen efter att alla trådar har gjort sina beräkningar, så att du kan läsa ut g.nodes[t].e på raden efter */
		
		g.nodes[t].e
	}

	fn find_admissible_edge(&self, u: usize) -> Option<(usize, usize)> {
		// implementation of the find_admissible_edge operation
		let p = &mut self.adj[u].clone(); // LinkedList<usize> of edge indices.
		let mut found: Option<(usize, usize)> = None; // Option<usize> is an enum that can either be Some(usize) or None. It is used to represent the possibility of a value being present or absent. In this case, it is used to represent the index of the neighbor node that we can push to. If we find a valid neighbor, we will set v to Some(neighbor_index), otherwise it will remain None.
		let mut b: i32; // b is used to determine the direction of the edge. If u is the source node of the edge, b will be 1, otherwise it will be -1. This is used to determine whether
		let mut v: usize; // v is the index of the neighbor node that we can push to. It will be set to the index of the neighbor node if we find a valid edge to push to.

		while let Some(e) = p.pop_front() { // same as: while (p != NULL) {
			if u == self.edges[e].u {
				v = self.edges[e].v;
				b = 1;
			} else {
				v = self.edges[e].u;
				b = -1;
			}

			if self.nodes[u].h > self.nodes[v].h && b * self.edges[e].f < self.edges[e].c {
				found = Some((v,e)); // Some är en del av datatypen Option i Rust.
				break;
			}
			
		}

		return found;
	}

	fn next_work_phase(&mut self, u: usize) {
		if !self.queued_this_round[u] {
			self.queued_this_round[u] = true;
			self.nextWorkload.push(u);
		}
	}

}

// skapa en ny instans av decision vid varje beslut
fn record_decision(sender: usize, receiver: usize, edge_index: usize, amount: i32, is_relabel: bool) -> Decision {
	Decision {
		sender,
		receiver,
		edge_index,
		amount,
		is_relabel,
	}
}

fn apply_decision(graph: &mut Graph, d: Decision) {
    let sender = d.sender;

	// Om vi ska relabela, så gör vi det och gå vidare
    if d.is_relabel {
        graph.relabel(sender);
        graph.next_work_phase(sender);
    } else {
        let receiver = d.receiver;
        let amount = d.amount;

		// Bestämmer riktning
        if sender == graph.edges[d.edge_index].u {
            graph.edges[d.edge_index].f += amount;
        } else {
            graph.edges[d.edge_index].f -= amount;
        }

		// Kollar om sändarens excess är tom
        let receiver_was_empty = graph.nodes[receiver].e == 0;
		// subtraherar/adderar excessen
        graph.nodes[sender].e -= amount;
        graph.nodes[receiver].e += amount;

		// Kolla avslut
        if receiver_was_empty
            && receiver != graph.source()
            && receiver != graph.sink()
        {
            graph.next_work_phase(receiver);
        }

        if graph.nodes[sender].e > 0 {
            graph.next_work_phase(sender);
        }
    }
	
}


fn decide(graph: &Graph, sender: usize) -> Decision {

	let found = graph.find_admissible_edge(sender);
	// implementation of the decide operation
	match found {
		Some((receiver, edge_index)) => {
			Decision {
				sender: sender,
				receiver,
				edge_index: edge_index,
				amount: graph.push_amount(sender, edge_index),
				is_relabel: false,
			}
		}
		None => {
			Decision {
				sender,
				receiver: 0,
				edge_index: 0,
				amount: 0,
				is_relabel: true,
			}
		}
	}
}

fn next_workload(graph: &Graph, current_workload: &Vec<usize>) -> Vec<usize> {
	let mut next_workload = Vec::new();
	for &u in current_workload {
		if graph.nodes[u].e > 0 {
			next_workload.push(u);
		}
	}
	next_workload
}

fn create_threads(
	shared: &RwLock<Graph>,
	barrier: &Barrier,
	decision_list: &[Mutex<Decision>],
	thread_id: usize,
) {
	loop {
		let count = shared.read().unwrap().currentWorkload.len();
		if count == 0 {
			break;
		}
 
		{
			// shared read lock: all threads can hold it at once
			let g = shared.read().unwrap();
			for i in (thread_id..count).step_by(N) {
				let d = decide(&g, g.currentWorkload[i]);
				*decision_list[i].lock().unwrap() = d;
			}
		} // the read lock MUST be dropped before the barrier, or the leader's write() deadlocks
 
		// is_leader() == PTHREAD_BARRIER_SERIAL_THREAD, basically kör en tråd
		if barrier.wait().is_leader() {
			let mut guard = shared.write().unwrap(); // Låser hela grafen för att vi bara har en tråd som ska jobba
			let g = &mut *guard;
 
			g.nextWorkload.clear();
			for q in g.queued_this_round.iter_mut() { // Nollställer
				*q = false;
			}
 
			for i in 0..count {
				let d = *decision_list[i].lock().unwrap(); // wrappa upp det i våran decision lista
				apply_decision(g, d);
			}
 
			std::mem::swap(&mut g.currentWorkload, &mut g.nextWorkload); // swappar det som vi har kvar tills nästa runda
		}
 
		barrier.wait(); // everyone sees the new work list
	}
}

fn main() {
	// read!() is reading input
	let n: usize = read!();		/* n nodes.						*/
	let m: usize = read!();		/* m edges.						*/
	let _c: usize = read!();	/* underscore avoids warning about an unused variable.	*/
	let _p: usize = read!();	/* c and p are in the input from 6railwayplanning.	*/
	let mut node = vec![]; // creating a vector to hold the nodes of the graph. The vector is initially empty and will be populated with Node structs as they are created.
	let mut edge = vec![]; // same here with edges. creating a vector to hold the edges of the graph. The vector is initially empty and will be populated with Edge structs as they are created.
	let mut adj: Vec<LinkedList<usize>> =Vec::with_capacity(n); // creating a vector of linked lists to hold the adjacency list representation of the graph. Each linked list will hold the indices of the edges that are adjacent to a given node. The vector is initialized with a capacity of n, which is the number of nodes in the graph.
	// let mut excess: VecDeque<usize> = VecDeque::new(); // creating a double-ended queue to hold the indices of the nodes that have excess preflow. The queue is initially empty and will be populated with the indices of the nodes as they are processed.
	let debug = true;

	let s = 0; // source node is always 0
	let t = n-1; // sink node is always n-1, the end node

	println!("n = {}", n);
	println!("m = {}", m);

	// initiating the graph, create nodes and adjacency list
	for i in 0..n {
		let u:Node = Node::new(i);
		node.push(u); 
		adj.push(LinkedList::new());
	}

	// read edges and create adjacency list
	for i in 0..m {
		let u: usize = read!();
		let v: usize = read!();
		let c: i32 = read!();
		let e:Edge = Edge::new(u,v,c);
		adj[u].push_back(i);
		adj[v].push_back(i);
		edge.push(e); 
	}

	if debug {
		for i in 0..n {
			print!("adj[{}] = ", i);
			let iter = adj[i].iter();

			for e in iter {
				print!("e = {}, ", e);
			}
			println!("");
		}
	}

	// println!("initial pushes");
	// let iter = adj[s].iter();

	let mut g = Graph::new(node, edge, adj);
	let begin = Instant::now();       // starta klockan efter inläsningen
	println!("f = {}", g.preflow());
	let elapsed = begin.elapsed();    // stoppa klockan

	eprintln!("time: {:?}", elapsed);

}
