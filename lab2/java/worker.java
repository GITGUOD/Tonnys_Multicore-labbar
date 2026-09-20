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
	long[] syncWait;
	int numberOfThreads;
	int threadsProcessed[];

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
		this.numberOfThreads = 4;
		this.syncWait = new long[numberOfThreads]; // Sparar hur länge de väntar
		this.threadsProcessed = new int[numberOfThreads];

	}

	void enter_excess(Node u)
	{
						// System.out.println("Letsgoo");
		if (u != node[s] && u != node[t] && u.e > 0 && !u.inExcess) {
			u.next = excess;
			excess = u;
			u.inExcess = true;
		}
	}

	Node other(Edge a, Node u)
	{
		if (a.u == u)	
			return a.v;
		else
			return a.u;
	}

	int residual(Edge a, Node from)
	{
		if (a.u == from)
			return a.c - a.f;   // forwarda oanvänd kapacitet
		else
			return a.c + a.f;          // backward: flow that can be canceled
	}

	void relabel(Node u)
	{
		int minimum_h = Integer.MAX_VALUE;
		// Vi vill gå igenom våran adj lista, hitta den minsta och skriva om våran höjd till den + 1.

		for(Edge a : u.adj) { // Kolla genom varje granne

			// int availableCapacity = (a.c - a.f); // kapacitet - flöde för att see hur mycket vi har
			int availableCapacity = residual(a, u);
			if(availableCapacity > 0) { // finns inget flöde så vi gör inget
				Node v = other(a, u); // hämta grannen
				if(v.h < minimum_h) {
					minimum_h = v.h;
				}
			}
		}
		// Vi har hittat den minsta grannens höjd, men det är så klart om vi har hittat någon residual höjd
		if (minimum_h != Integer.MAX_VALUE) {
			u.h = minimum_h + 1;
		}

	}

	// void push(Node u, Node v, Edge a)
	// {
	// 			System.out.println("Pushing1");
	// 	int flow = Math.min(u.e, (a.c - a.f)); // Hämtar excess flödet mellan antigen Nod U:s flöde eller den maximala kapaciteten längst den vägen E/kanten (eftersom vi ej kan skicka mer än vad vägen har, samt att vi kan inte skicka mer än vad noden U har)
	// 	a.f += flow; // Ökar flödes i kanten mellan u och v
	// 	u.e -= flow; // minskar excessflödet i orginal sändaren
	// 	v.e += flow; // ökar excessflödet till mottagaren
	// 			System.out.println("Pushing2");

	// }

	void push(Node u, Node v, Edge a) {

		int flow = Math.min(u.e, residual(a, u));
		if (a.u == u)
			a.f += flow;
		else
			a.f -= flow;

		u.e -= flow;
		v.e += flow;
	}

	public void lockPair(Node u, Node v) {
		// Vi låser utifrån lock index, en regel som säkerställer att vi aldrig kan få tag på samma nod via modifikation
		// System.out.println("debugLockPair1");
		if(u.i < v.i) {
			// Låsa i rätt riktning
			u.nodeLock.lock();
			v.nodeLock.lock();
					// System.out.println("debugLockPair2");
		} else {
			v.nodeLock.lock();
			u.nodeLock.lock();
					// System.out.println("debugLockPair3");
		}
	}

	public void discharge(Node u) {
		// System.out.println("debugDischarge1");
		u.nodeLock.lock(); //Lås våran nod som vi ska discharga då processen börja //lock count = 1;

		while(u.e > 0) { //Medans vi har någon excess från våran sändare
			boolean pushed = false;
			// Släpp det vi håller på med
			u.nodeLock.unlock(); //lcok count för u = 0
			for(Edge a : u.adj) { // För varje granne/kant till noden u
				// int availableCapacity = (a.c - a.f); // kapacitet - flöde för att see hur mycket vi har
				int availableCapacity = residual(a, u);
				Node v = other(a, u); // Hämta grannen
				if(availableCapacity > 0 && u.h == (v.h + 1)) { // Kolla om våra conditions, rätt höjd, om vi har någon kapacitet o skicka etc
					// System.out.println("debugDischarge2");
					lockPair(u, v); //Lås eftersom vi ska börja modifikationen om villkoren är rätt, dock kan något/staten har ändrats när vi har kommit hit, vi behöver verificikation
					// lock count för u och v = 1
					boolean success = verification(u, v, a);

					if(success) {
					// Efter att våran granne har fått excess behöver vi lägga den till våran excess lista så att excessen kan behandlas vid nästa nod
					Node source = node[s];
					Node sink = node[t];
					pushed = true;
						if (v != source && v != sink && v.e > 0) {
							// Låsa innan vi gör en enter_excess och signalera att alla andra trådar kan nu bearbeta nästa
							excessLock.lock();
							try {
								enter_excess(v);
								excessIsEmpty.signalAll();
							} finally {
								excessLock.unlock();
							}
						}						
					}

					v.nodeLock.unlock(); //Här är vi klar
					u.nodeLock.unlock();
					if(success) break; // Vi har nu pushat och är klar, breaka bort till while-loopen
				}

			}
			
			u.nodeLock.lock(); //Vi behöverl åsa u innan vi relabela eller fortsätter med loopen igen
			if(!pushed) {
				relabel(u); // relabala
			}
			
		}

		u.nodeLock.unlock();
		
	}

	public boolean verification(Node u, Node v, Edge a) {
		boolean pushed = false;
		// int freshAvailableCapacity = (a.c - a.f);
		int freshAvailableCapacity = residual(a, u);
		if (u.e > 0 && freshAvailableCapacity > 0 && u.h == v.h + 1) {
			push(u, v, a);
			pushed = true;

		}
		return pushed;
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
		Node sink = node[t];

		// Vi behöver göra initiella push från källan:
		iter = source.adj.listIterator();
		while (iter.hasNext()) {
			a = iter.next();

			v = other(a, source);
			// Första pushen från källan är speciell och vi kan därför inte anvädna push metodiken, vi kan bara pusha så mycket som våran kapacitet/flöde tillåter
			// a.f = a.c;
			// source.e -= a.c;
			// v.e += a.c;
			if (a.u == source) {
				a.f = a.c;
			}
			else {
				a.f = -a.c;
			}

			source.e -= a.c;
			v.e += a.c;

			if((v != source) && v != sink && (v.e > 0)) { // Vi kan påbörja bearbeta våran granne nu
				enter_excess(v);

			}

		}

		Thread[] workers = new Thread[numberOfThreads]; // Antalet trådar
		for(int i = 0; i < numberOfThreads; i++) {
			final int id = i;
			workers[id] = new Thread(() -> workerLoop(id));
			workers[id].start();
		}

		// Vi behöver kolla alla trådarna innan vi avslutar våran algo
		try {

			for(int j = 0; j < numberOfThreads; j++) {
				Thread th = workers[j];
				th.join();
			}

		} catch (Exception e) {
			System.out.println("Error: " + e);
		}

		// while (excess != null) {
		// 	u = excess;
		// 	v = null;
		// 	a = null;
		// 	excess = u.next;

		// 	iter = u.adj.listIterator();
		// 	while (iter.hasNext()) {
		// 		a = iter.next();
		// 	}

		// 	if (v != null)
		// 		push(u, v, a);
		// 	else
		// 		relabel(u);
		// }

		return sink.e;
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
			long t0 = System.nanoTime();

			Node u = null;
			excessLock.lock(); // vi låser först eftersom vi gör en ny transaction med en tråd
			try {
				// När tråden ska dö
				while(excess == null) {
					if(activeThreads == 0) {
						System.out.println("Thread " + workerId + " terminated: processed " + threadsProcessed[workerId] + " nodes, waited " + (syncWait[workerId] / 1e6) + " ms on synchronization");
						return;
					}
					// Om vi har jobb, vänta
					excessIsEmpty.await();
				}

				// Nu är det trådens tur och vi plockar upp noderna i excess listan som ska bearbetas / poppa första noden
				u = excess;
				excess = u.next; // Gå till nästa nod eftersom vi plockar ut en nod
				u.next = null; // den vi har plockat fram tar vi bort länken

				activeThreads++; //signalera att vi nu ska börja jobba
				// System.out.println(Thread.currentThread().getName() + " locking node " + u.i);
			} catch (Exception e) {
				System.out.print("Error: " + e);
			} finally {
				// System.out.print("Unlocking?");
				excessLock.unlock(); // Efter att vi har hämtat noden och ska bearbeta den kan vi äntligen släppa låset så att de andra kan ta nästa nod
			}
				// System.out.println("Time to discharge");
			syncWait[workerId] += (System.nanoTime() - t0);
			discharge(u); // discharge den noden vi har plockat, här behöver vi inte låsa eftersom vi behöver inte blocka dom andra trådarna
			
			long t1 = System.nanoTime();
			excessLock.lock(); // Sedan låser vi igen
			try {
				u.inExcess = false;
				if (u.e > 0) { //  Om den fortfarande har excess
					enter_excess(u);
				}
				activeThreads--;
				excessIsEmpty.signalAll(); //signalera alla andra trådar att vi är klara!

			} catch (Exception e) {
				System.out.println("Error: " + e);
			} finally {
				excessLock.unlock();
			}
		
			syncWait[workerId] += (System.nanoTime() - t1);
        threadsProcessed[workerId]++;


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
	volatile int	h; // Vi hade datarace på h eftersom alla noder läser h
	int	e;
	int	i;
	ReentrantLock nodeLock;
	boolean inExcess;
	Node	next;
	LinkedList<Edge>	adj;

	Node(int i)
	{
		this.i = i;
		adj = new LinkedList<Edge>();
		nodeLock = new ReentrantLock();
		inExcess = false;
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
		System.out.println("Input: ");
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
