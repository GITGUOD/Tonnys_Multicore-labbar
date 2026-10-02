#[macro_use] extern crate text_io; // importing a crate, a library which in this case text_io, which is used for reading input from stdin. It's like import text_io
// #[macro_use] is basically attribute that allows us to use macros from the text_io crate without having to prefix them with the crate name. In this case, it allows us to use the read! macro directly.
// macro is a way to define reusable code snippets that can be expanded at compile time. In this case, the read! macro is used to read input from stdin and parse it into the specified type.
// Without #[macro_use], we would have to write text_io::read! instead of just read!. This is a convenience feature that makes the code cleaner and easier to read.
use std::sync::{Mutex,Arc}; // use statements for importing the Mutex and Arc types from the std::sync module. Arc is a thread-safe reference-counting pointer that allows multiple threads to share ownership of the same data. Mutex is a mutual exclusion primitive that allows only one thread to access the data at a time, preventing data races.
use std::cmp; // use statement for importing the cmp module from the std library. The cmp module provides functions for comparing values, such as min and max.
use std::thread;
use std::collections::VecDeque; // use statement for importing the VecDeque type from the std::collections module. VecDeque is a double-ended queue that allows efficient insertion and removal of elements from both ends.

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
	n: usize,
	m: usize,
	nodes: Vec<Arc<Mutex<Node>>>,
	edges: Vec<Arc<Mutex<Edge>>>,
	adj: Vec<LinkedList<usize>>,
	s: usize,
	t: usize, // source and sink nodes indexes, we dont need to declare them as Node because our array of nodes is already holding the Node structs, we just need to know the index of the source and sink nodes in that array.
}

impl Graph {

	fn enterExcess(graph_t* g, node_t* v) {
		// implementation of the enterExcess operation
		/* put v at the front of the list of nodes
		* that have excess preflow > 0.
		*
		* note that for the algorithm, this is just
		* a set of nodes which has no order but putting it
		* it first is simplest.
		*
		*/

		if (v != g.t && v != g.s) {
			v->next = g->excess;
			g->excess = v;
		}
	}

	fn push() {
		// implementation of the push operation
	}

	fn relabel() {
		// implementation of the relabel operation
	}

	fn preflow() {
		// implementation of the preflow operation
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
		node.push(Arc::new(Mutex::new(u))); 
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
		edge.push(Arc::new(Mutex::new(e))); 
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

	while !excess.is_empty() {
		let mut c = 0;
		let u = excess.pop_front().unwrap();
	}

	println!("f = {}", 0);

}
