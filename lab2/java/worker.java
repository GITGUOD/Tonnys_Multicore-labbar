import java.util.Scanner;
import java.util.concurrent.locks.*;
import java.util.Iterator;
import java.util.ListIterator;
import java.util.LinkedList;
import java.io.*;

class Graph {

	ReentrantLock excessLock;
	Condition excessIsEmpty;
	int activeThreads;
	int	s;
	int	t;
	int	n;
	int	m;
	Node	excess;		// list of nodes with excess preflow
	Node	node[];
	Edge	edge[];

	Graph(Node node[], Edge edge[])
	{
		this.node	= node;
		this.n		= node.length;
		this.edge	= edge;
		this.m		= edge.length;
		// Init våra attribut.
		this.excessLock = new ReentrantLock();
		this.excessIsEmpty = excessLock.newCondition();
		this.activeThreads = 0;
	}

	void enter_excess(Node u)
	{
		if (u != node[s] && u != node[t]) {
			u.next = excess;
			excess = u;
		}
	}

	Node other(Edge a, Node u)
	{
		if (a.u == u)	
			return a.v;
		else
			return a.u;
	}

	void relabel(Node u)
	{
		int minimum_h = Integer.MAX_VALUE;
		// Vi vill gå igenom våran adj lista, hitta den minsta och skriva om våran höjd till den + 1.
		for(Edge a : u.adj) { // Kolla genom varje granne
			int availableCapacity = (a.c - a.f); // kapacitet - flöde för att see hur mycket vi har
			if(availableCapacity > 0) { // finns inget flöde så vi gör inget
				Node v = other(a, u); // hämta grannen
				if(v.h < minimum_h) {
					minimum_h = v.h;
				}
			}
		}

		// Vi har hittat den minsta grannens höjd
		u.h = minimum_h + 1;
	}

	void push(Node u, Node v, Edge a)
	{
		int flow = Math.min(u.e, (a.c - a.f)); // Hämtar excess flödet mellan antigen Nod U:s flöde eller den maximala kapaciteten längst den vägen E/kanten (eftersom vi ej kan skicka mer än vad vägen har, samt att vi kan inte skicka mer än vad noden U har)
		a.f += flow; // Ökar flödes i kanten mellan u och v
		u.e -= flow; // minskar excessflödet i orginal sändaren
		v.e += flow; // ökar excessflödet till mottagaren
	}

	public void discharge(Node u) {

		while(u.e > 0) { //Medans vi har någon excess från våran sändare

			for(Edge a : u.adj) { // För varje granne/kant till noden u
				int availableCapacity = (a.c - a.f); // kapacitet - flöde för att see hur mycket vi har
				Node v = other(a, u); // Hämta grannen
				if(availableCapacity > 0 && u.h == (v.h + 1)) { // Kolla om våra conditions, rätt höjd, om vi har någon kapacitet o skicka etc
					push(u, v, a);
					// Efter att våran granne har fått excess behöver vi lägga den till våran excess lista så att excessen kan behandlas vid nästa nod
					if (v != node[s] && v != node[t] && v.e > 0) {
						enter_excess(v);
					}
					continue; // Vi har nu pushat och är klar, continue bort från while-loopen
				}

			}

			relabel(u); // relabala

		}
		
	}

	int preflow(int s, int t)
	{
		ListIterator<Edge>	iter;
		int			b;
		Edge			a;
		Node			u;
		Node			v;
		
		this.s = s;
		this.t = t;
		Node source = node[s];
		source.h = n; // Sätter vi höjden

		// Vi behöver göra initiella push från källan:
		iter = source.adj.listIterator();
		while (iter.hasNext()) {
			a = iter.next();

			node[s].e += a.c;

			push(source, other(a, source), a);
		}

		while (excess != null) {
			u = excess;
			v = null;
			a = null;
			excess = u.next;

			iter = u.adj.listIterator();
			while (iter.hasNext()) {
				a = iter.next();
			}

			if (v != null)
				push(u, v, a);
			else
				relabel(u);
		}

		return node[t].e;
	}
	/* 
	Paralleliseringen eller hur man stavar det
	Främst för att trådarna ska göra tre saker:

		Hämta ett jobb från arbetsstationen
		Utföra jobbet (discharge)
		Berätta att de är klara så andra kan fortsätta
	*/
	public void workerLoop(int workerId) {
		// Den ska jobba hela tiden
		while(true) {
			Node u = null;
			excessLock.lock(); // vi låser först eftersom vi gör en ny transaction med en tråd
			try {
				// När tråden ska dö
				while(excess == null && activeThreads == 0) {
					excessLock.unlock();
					return;
				}
				// Om vi har jobb, vänta
				while(excess != null) {
					excessIsEmpty.wait();
				}

				// Nu är det trådens tur och vi plockar upp noderna i excess listan som ska bearbetas / poppa första noden
				u = excess;
				excess = u.next; // Gå till nästa nod eftersom vi plockar ut en nod
				activeThreads++; //signalera att vi nu ska börja jobba
			} catch (Exception e) {
				System.out.print("Error: " + e);
			} finally {
				excessLock.unlock(); // Efter att vi har hämtat noden och ska bearbeta den kan vi äntligen släppa låset så att de andra kan ta nästa nod
			}

			discharge(u); // discharge den noden vi har plockat, här behöver vi inte låsa eftersom vi behöver inte blocka dom andra trådarna
			excessLock.lock(); // Sedan låser vi igen
			try {
				activeThreads--;
				excessIsEmpty.notifyAll(); //signalera alla andra trådar att vi är klara!

			} catch (Exception e) {
				System.out.println("Error: " + e);
			} finally {
				excessLock.unlock();
			}


		}

	}
}

class Worker extends Thread {

	int workerId;
	Graph g;

	public Worker(Graph g, int workerId) {
		this.g = g;
		this.workerId = workerId;
	}

	public void run() {
		g.workerLoop(workerId);
	}
}

class Node {
	int	h;
	int	e;
	int	i;
	Node	next;
	LinkedList<Edge>	adj;

	Node(int i)
	{
		this.i = i;
		adj = new LinkedList<Edge>();
	}
}

class Edge {
	Node	u;
	Node	v;
	int	f; // flöde
	int	c; // kapacitet

	Edge(Node u, Node v, int c)
	{
		this.u = u;
		this.v = v;
		this.c = c;

	}
}

class Preflow {
	public static void main(String args[])
	{
		double	begin = System.currentTimeMillis();
		Scanner s = new Scanner(System.in);
		int	n;
		int	m;
		int	i;
		int	u;
		int	v;
		int	c;
		int	f;
		Graph	g;

		n = s.nextInt();
		m = s.nextInt();
		s.nextInt();
		s.nextInt();
		Node[] node = new Node[n];
		Edge[] edge = new Edge[m];

		for (i = 0; i < n; i += 1)
			node[i] = new Node(i);

		for (i = 0; i < m; i += 1) {
			u = s.nextInt();
			v = s.nextInt();
			c = s.nextInt(); 
			edge[i] = new Edge(node[u], node[v], c);
			node[u].adj.addLast(edge[i]);
			node[v].adj.addLast(edge[i]);
		}

		g = new Graph(node, edge);
		f = g.preflow(0, n-1);
		double	end = System.currentTimeMillis();
		System.out.println("t = " + (end - begin) / 1000.0 + " s");
		System.out.println("f = " + f);
	}
}
