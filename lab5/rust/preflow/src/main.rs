#[macro_use] extern crate text_io; // importing a crate, a library which in this case text_io, which is used for reading input from stdin. It's like import text_io
// #[macro_use] is basically attribute that allows us to use macros from the text_io crate without having to prefix them with the crate name. In this case, it allows us to use the read! macro directly.
// macro is a way to define reusable code snippets that can be expanded at compile time. In this case, the read! macro is used to read input from stdin and parse it into the specified type.
// Without #[macro_use], we would have to write text_io::read! instead of just read!. This is a convenience feature that makes the code cleaner and easier to read.
// use std::sync::{Mutex,Arc}; // use statements for importing the Mutex and Arc types from the std::sync module. Arc is a thread-safe reference-counting pointer that allows multiple threads to share ownership of the same data. Mutex is a mutual exclusion primitive that allows only one thread to access the data at a time, preventing data races.
use std::collections::VecDeque; // use statement for importing the VecDeque type from the std::collections module. VecDeque is a double-ended queue that allows efficient insertion and removal of elements from both ends.
use std::collections::LinkedList;
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

struct Graph {
	nodes: Vec<Node>,
	edges: Vec<Edge>,
	adj: Vec<LinkedList<usize>>,
	excess: VecDeque<usize>,
	
}
	
impl Graph {

	// Konstruktorn
	fn new (u: Vec<Node>, e: Vec<Edge>, a: Vec<LinkedList<usize>>, ex: VecDeque<usize>) -> Graph {
		Graph {
			nodes: u,
			edges: e,
			adj: a,
			excess: ex,
		}
	}

	// se under
	fn s(&self) -> usize {
		0
	}

	// Get metoder för att hämta source och sink index.
	fn t(&self) -> usize {
		self.nodes.len() - 1
	}

	fn add_edge(&mut self, u: usize, v: usize, c: i32) {
		let index = self.edges.len();
		self.edges.push(Edge::new(u, v, c));
		self.adj[u].push_back(index);
		self.adj[v].push_back(index);
	}

	fn other(&self, u: usize, e: &Edge) -> usize {
		if u == e.u {
			e.v
		} else {
			e.u
		}
	}

	fn enter_excess(&mut self, v: usize) {
		// implementation of the enterExcess operation
		/* put v at the front of the list of nodes
		* that have excess preflow > 0.
		*
		* note that for the algorithm, this is just
		* a set of nodes which has no order but putting it
		* it first is simplest.
		*
		*/

		let s = self.s();
		let t = self.t();

		if v != t && v != s {
			self.excess.push_front(v);
		}
	}

	fn leave_excess(&mut self) -> Option<usize> {
		self.excess.pop_front()
	}

	fn push(&mut self, u: usize, v: usize, edge_index: usize) {
		// implementation of the push operation
			
		let d: i32;	/* remaining capacity of the edge. */

		
		if u == self.edges[edge_index].u {
			d = std::cmp::min(self.nodes[u].e, self.edges[edge_index].c - self.edges[edge_index].f);
			self.edges[edge_index].f += d;
		} else {
			d = std::cmp::min(self.nodes[u].e, self.edges[edge_index].c + self.edges[edge_index].f);
			self.edges[edge_index].f -= d;
		}

		println!("pushing {}\n", d);

		self.nodes[u].e -= d;
		self.nodes[v].e += d;

		/* the following are always true. */

		assert!(d >= 0);
		assert!(self.nodes[u].e >= 0);
		assert!(self.edges[edge_index].f.abs() <= self.edges[edge_index].c);

		if self.nodes[u].e > 0 {

			/* still some remaining so let u push more. */

			self.enter_excess(u);
		}

		if self.nodes[v].e == d {

			/* since v has d excess now it had zero before and
			* can now push.
			*
			*/

			self.enter_excess(v);
		}
		
	}
	// mut är en förkortning för mutable (muterbar), alltså att något får ändras.
	fn relabel(&mut self, u: usize) {
		// implementation of the relabel operation
		self.nodes[u].h += 1;
		self.enter_excess(u);
	}

	fn preflow(&mut self) -> i32 {
		// implementation of the preflow operation

		let s = self.s();
		let t = self.t();
		self.nodes[s].h = self.nodes.len() as i32;

		let p = &mut self.adj[s].clone(); // LinkedList<usize> of edge indices.

		/* start by pushing as much as possible (limited by
		* the edge capacity) from the source to its neighbors.
		*
		*/

		while let Some(e) = p.pop_front() { // same as: while (p != NULL) { e = p.edge; p = p.next; }

			self.nodes[s].e += self.edges[e].c;
			self.push(s, self.other(s, &self.edges[e]), e); // & is a reference operator, it allows us to pass a reference to the edge instead of moving the ownership of the edge into the function. This is important because we want to keep the edge in the graph and not lose it after the push operation.
		}
		
		/* then loop until only s and/or t have excess preflow. */

		while let Some(u) = self.leave_excess() {

			/* u is any node with excess preflow. */

			/* if we can push we must push and only if we could
			* not push anything, we are allowed to relabel.
			*
			* we can push to multiple nodes if we wish but
			* here we just push once for simplicity.
			*
			*/

			let p = &mut self.adj[u].clone(); // LinkedList<usize> of edge indices. We clone the adjacency list of u because we will be modifying it during the loop and we don't want to affect the original adjacency list.
			let mut found: Option<(usize, usize)> = None; // Option<usize> is an enum that can either be Some(usize) or None. It is used to represent the possibility of a value being present or absent. In this case, it is used to represent the index of the neighbor node that we can push to. If we find a valid neighbor, we will set v to Some(neighbor_index), otherwise it will remain None.
			let mut b: i32; // b is used to determine the direction of the edge. If u is the source node of the edge, b will be 1, otherwise it will be -1. This is used to determine whether
			let mut v: usize; // v is the index of the neighbor node that we can push to. It will be set to the index of the neighbor node if we find a valid edge to push to.

			while let Some(e) = p.pop_front() { // same as: while (p != NULL) {
				// e = p.edge; C kod, above does the same as this two rows.
				// p = p.next;

				if u == self.edges[e].u {
					v = self.edges[e].v;
					b = 1;
				} else {
					v = self.edges[e].u;
					b = -1;
				}

				if self.nodes[u].h > self.nodes[v].h && b * self.edges[e].f < self.edges[e].c {
					found = Some((v,e));
					break;
				}
				
			}

			if let Some((v, e)) = found {     // replaces: if (v != NULL)
				self.push(u, v, e);
			} else {
				self.relabel(u);
			}
		}

		return self.nodes[t].e;
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
	let mut excess: VecDeque<usize> = VecDeque::new(); // creating a double-ended queue to hold the indices of the nodes that have excess preflow. The queue is initially empty and will be populated with the indices of the nodes as they are processed.
	let debug = false;

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

	println!("initial pushes");
	let iter = adj[s].iter();

	// but nothing is done here yet...
	let mut g = Graph::new(node, edge, adj, excess.clone());
	println!("f = {}", g.preflow());

	while !excess.is_empty() {
		let c = 0;
		let u = excess.pop_front().unwrap();
	}

	// println!("f = {}", 0);

}
