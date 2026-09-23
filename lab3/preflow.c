/* This is an implementation of the preflow-push algorithm, by
 * Goldberg and Tarjan, for the 2021 EDAN26 Multicore programming labs.
 *
 * It is intended to be as simple as possible to understand and is
 * not optimized in any way.
 *
 * You should NOT read everything for this course.
 *
 * Focus on what is most similar to the pseudo code, i.e., the functions
 * preflow, push, and relabel.
 *
 * Some things about C are explained which are useful for everyone  
 * for lab 3, and things you most likely want to skip have a warning 
 * saying it is only for the curious or really curious. 
 * That can safely be ignored since it is not part of this course.
 *
 * Compile and run with: make
 *
 * Enable prints by changing from 1 to 0 at PRINT below.
 *
 * Feel free to ask any questions about it on Discord 
 * at #lab0-preflow-push
 *
 * A variable or function declared with static is only visible from
 * within its file so it is a good practice to use in order to avoid
 * conflicts for names which need not be visible from other files.
 *
 */
 
#include <assert.h>
#include <ctype.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <limits.h>

/* Barrier*/
#include "pthread_barrier.h"
// Angle brackets (<...>) tell the compiler to search only system include directories (like /usr/include), not your current folder.
// Since pthread_barrier.h is a file you wrote yourself, sitting next to preflow.c, you need quotes instead:

pthread_barrier_t barrier; // Our barrier  

#define PRINT		0	/* enable/disable prints. */

/* the funny do-while next clearly performs one iteration of the loop.
 * if you are really curious about why there is a loop, please check
 * the course book about the C preprocessor where it is explained. it
 * is to avoid bugs and/or syntax errors in case you use the pr in an
 * if-statement without { }.
 *
 */

#if PRINT
#define pr(...)		do { fprintf(stderr, __VA_ARGS__); } while (0)
#else
#define pr(...)		/* no effect at all */
#endif
#define MAXN 128
#define N 4

#define MIN(a,b)	(((a)<=(b))?(a):(b))

/* introduce names for some structs. a struct is like a class, except
 * it cannot be extended and has no member methods, and everything is
 * public.
 *
 * using typedef like this means we can avoid writing 'struct' in 
 * every declaration. no new type is introduded and only a shorter name.
 *
 */

typedef struct graph_t	graph_t;
typedef struct node_t	node_t;
typedef struct edge_t	edge_t;
typedef struct list_t	list_t;

struct list_t {
	edge_t*		edge;
	list_t*		next;
};

// A decision_t just a record of "what to do", so typ en sändare som skickar till recever, kant, hur mycket, ska vi relabala etc.
typedef struct {
    node_t*  sender;
    node_t*  receiver;   
    edge_t*  edge;        
    int      amount;      // push amount, or ignored for relabel
    int      is_relabel;  // 0 = push, 1 = relabel
    int      new_height;  // only if is_relabel
} decision_t;

typedef struct {
    graph_t* g;
    int      thread_id;
} thread_args_t;
// definiera en tråd, den har både en tråd och ett ansvarsområde i grafen.

pthread_t workers[N]; //trådar
decision_t*     decisionList;
node_t**    currentWorkload;   // denna rundas aktiva noder
int         currentCount; // Antal noder som ska bearbetas
int* queuedThisRound;

node_t**    nextWorkload;      // nästa runda
int         nextCount;         

struct node_t {
	int		h;	/* height.			*/
	int		e;	/* excess flow.			*/
	list_t*		edge;	/* adjacency list.		*/
	node_t*		next;	/* with excess preflow.		*/
};

struct edge_t {
	node_t*		u;	/* one of the two nodes.	*/
	node_t*		v;	/* the other. 			*/
	int		f;	/* flow > 0 if from u to v.	*/
	int		c;	/* capacity.			*/
};

struct graph_t {
	int		n;	/* nodes.			*/
	int		m;	/* edges.			*/
	node_t*		v;	/* array of n nodes.		*/
	edge_t*		e;	/* array of m edges.		*/
	node_t*		s;	/* source.			*/
	node_t*		t;	/* sink.			*/
	node_t*		excess;	/* nodes with e > 0 except s,t.	*/
};

/* a remark about C arrays. the phrase above 'array of n nodes' is using
 * the word 'array' in a general sense for any language. in C an array
 * (i.e., the technical term array in ISO C) is declared as: int x[10],
 * i.e., with [size] but for convenience most people refer to the data
 * in memory as an array here despite the graph_t's v and e members 
 * are not strictly arrays. they are pointers. once we have allocated
 * memory for the data in the ''array'' for the pointer, the syntax of
 * using an array or pointer is the same so we can refer to a node with
 *
 * 			g->v[i]
 *
 * where the -> is identical to Java's . in this expression.
 * 
 * in summary: just use the v and e as arrays.
 * 
 * a difference between C and Java is that in Java you can really not
 * have an array of nodes as we do. instead you need to have an array
 * of node references. in C we can have both arrays and local variables
 * with structs that are not allocated as with Java's new but instead
 * as any basic type such as int.
 * 
 */

static char* progname;

#if PRINT

static int id(graph_t* g, node_t* v)
{
	/* return the node index for v.
	 *
	 * the rest is only for the curious.
	 *
	 * we convert a node pointer to its index by subtracting
	 * v and the array (which is a pointer) with all nodes.
	 *
	 * if p and q are pointers to elements of the same array,
	 * then p - q is the number of elements between p and q.
	 *
	 * we can of course also use q - p which is -(p - q)
	 *
	 * subtracting like this is only valid for pointers to the
	 * same array.
	 *
	 * what happens is a subtract instruction followed by a
	 * divide by the size of the array element.
	 *
	 */

	return v - g->v;
}
#endif


static edge_t* find_admissible_edge(node_t* u) {
    node_t*		s;
	node_t*		v;
	edge_t*		e;
	list_t*		p;
	int		b;


    p = u->edge; // hämta u's kant

    while (p != NULL) { //Om u har en granne
			e = p->edge; // gämtar vi 
			p = p->next;

			if (u == e->u) {
				v = e->v;
				b = 1;
			} else {
				v = e->u;
				b = -1;
			}

			if (u->h > v->h && b * e->f < e->c) {
                return e;
            }
		}
    return NULL;
}

static int findDirection(edge_t* edge, node_t* sender) {
	int direction = 0;

	if (sender == edge->u) {
        direction = 1;
	} else {
		direction = -1;
	}

	return direction;
}

static int f_pushAmount(edge_t* edge, node_t* sender) {
	int pushAmount = 0;

	if (sender == edge->u) {
 		pushAmount = MIN(sender->e, edge->c - edge->f);
	} else {
		pushAmount = MIN(sender->e, edge->c + edge->f);
	}

	return pushAmount;
}

static void record_decision(graph_t* graph, node_t* sender, node_t* receiver, edge_t* edge,
                             int amount, int is_relabel, int new_height) {

    int idx = sender - graph->v;

    decisionList[idx] = (decision_t){
        .sender = sender,
        .receiver = receiver,
        .edge = edge,
        .amount = amount,
        .is_relabel = is_relabel,
        .new_height = new_height
    };
}

void error(const char* fmt, ...)
{
	/* print error message and exit. 
	 *
	 * it can be used as printf with formatting commands such as:
	 *
	 *	error("height is negative %d", v->h);
	 *
	 * the rest is only for the really curious. the va_list
	 * represents a compiler-specific type to handle an unknown
	 * number of arguments for this error function so that they
	 * can be passed to the vsprintf function that prints the
	 * error message to buf which is then printed to stderr.
	 *
	 * the compiler needs to keep track of which parameters are
	 * passed in integer registers, floating point registers, and
	 * which are instead written to the stack.
	 *
	 * avoid ... in performance critical code since it makes 
	 * life for optimizing compilers much more difficult. but in
	 * in error functions, they obviously are fine (unless we are
	 * sufficiently paranoid and don't want to risk an error 
	 * condition escalate and crash a car or nuclear reactor 		 
	 * instead of doing an even safer shutdown (corrupted memory
	 * can cause even more damage if we trust the stack is in good
	 * shape)).
	 *
	 */

	va_list		ap;
	char		buf[BUFSIZ];

	va_start(ap, fmt);
	vsprintf(buf, fmt, ap);

	if (progname != NULL)
		fprintf(stderr, "%s: ", progname);

	fprintf(stderr, "error: %s\n", buf);
	exit(1);
}

static int next_int()
{
        int     x;
        int     c;

	/* this is like Java's nextInt to get the next integer.
	 *
	 * we read the next integer one digit at a time which is
	 * simpler and faster than using the normal function
	 * fscanf that needs to do more work.
	 *
	 * we get the value of a digit character by subtracting '0'
	 * so the character '4' gives '4' - '0' == 4
	 *
	 * it works like this: say the next input is 124
	 * x is first 0, then 1, then 10 + 2, and then 120 + 4.
	 *
	 */

	x = 0;
        while (isdigit(c = getchar()))
                x = 10 * x + c - '0';

        return x;
}

static void* xmalloc(size_t s)
{
	void*		p;

	/* allocate s bytes from the heap and check that there was
	 * memory for our request.
	 *
	 * memory from malloc contains garbage except at the beginning
	 * of the program execution when it contains zeroes for 
	 * security reasons so that no program should read data written
	 * by a different program and user.
	 *
	 * size_t is an unsigned integer type (printed with %zu and
	 * not %d as for int).
	 *
	 */

	p = malloc(s);

	if (p == NULL)
		error("out of memory: malloc(%zu) failed", s);

	return p;
}

static void* xcalloc(size_t n, size_t s)
{
	void*		p;

	p = xmalloc(n * s);

	/* memset sets everything (in this case) to 0. */
	memset(p, 0, n * s);

	/* for the curious: so memset is equivalent to a simple
	 * loop but a call to memset needs less memory, and also
 	 * most computers have special instructions to zero cache 
	 * blocks which usually are used by memset since it normally
	 * is written in assembler code. note that good compilers 
	 * decide themselves whether to use memset or a for-loop
	 * so it often does not matter. for small amounts of memory
	 * such as a few bytes, good compilers will just use a 
	 * sequence of store instructions and no call or loop at all.
	 *
	 */

	return p;
}


void init_phase_lists(graph_t* g) {
    currentWorkload = xmalloc(g->n * sizeof(node_t*));
    decisionList    = xmalloc(g->n * sizeof(decision_t));
    nextWorkload    = xmalloc(g->n * sizeof(node_t*));
    queuedThisRound = xcalloc(g->n, sizeof(int));
}

static void add_edge(node_t* u, edge_t* e)
{
	list_t*		p;

	/* allocate memory for a list link and put it first
	 * in the adjacency list of u.
	 *
	 */

	p = xmalloc(sizeof(list_t));
	p->edge = e;
	p->next = u->edge;
	u->edge = p;
}

static void connect(node_t* u, node_t* v, int c, edge_t* e)
{
	/* connect two nodes by putting a shared (same object)
	 * in their adjacency lists.
	 *
	 */

	e->u = u;
	e->v = v;
	e->c = c;

	add_edge(u, e);
	add_edge(v, e);
}

static graph_t* new_graph(FILE* in, int n, int m)
{
	graph_t*	g;
	node_t*		u;
	node_t*		v;
	int		i;
	int		a;
	int		b;
	int		c;
	
	g = xmalloc(sizeof(graph_t));

	g->n = n;
	g->m = m;
	
	g->v = xcalloc(n, sizeof(node_t));
	g->e = xcalloc(m, sizeof(edge_t));

	g->s = &g->v[0];
	g->t = &g->v[n-1];
	g->excess = NULL;

	for (i = 0; i < m; i += 1) {
		a = next_int();
		b = next_int();
		c = next_int();
		u = &g->v[a];
		v = &g->v[b];
		connect(u, v, c, g->e+i);
	}

	return g;
}

static void enter_excess(graph_t* g, node_t* v)
{
	/* put v at the front of the list of nodes
	 * that have excess preflow > 0.
	 *
	 * note that for the algorithm, this is just
	 * a set of nodes which has no order but putting it
	 * it first is simplest.
	 *
	 */

	if (v != g->t && v != g->s) {
		v->next = g->excess;
		g->excess = v;
	}
}

static void push(graph_t* g, node_t* sender, node_t* receiver, edge_t* edge, int amount)
{	
	//
    if (sender == edge->u) {
        edge->f += amount;
	} else {
        edge->f -= amount;
	}

    sender->e   -= amount;
    receiver->e += amount;

    assert(amount >= 0);
    assert(sender->e >= 0);
    assert(abs(edge->f) <= edge->c);
}



static void relabel(graph_t* graph, node_t* sender)
{
    int minimum_h = INT_MAX;
    list_t* p = sender->edge;

    while (p != NULL) {
        edge_t* a = p->edge;
        p = p->next;

        node_t* v;
        int residual;
        if (a->u == sender) {
            v = a->v;
            residual = a->c - a->f;
        } else {
            v = a->u;
            residual = a->c + a->f;
        }

        if (residual > 0 && v->h < minimum_h) {
            minimum_h = v->h;    // läses utan lås på v — okej, se motivering ovan
        }
    }

    if (minimum_h != INT_MAX) {
        sender->h = minimum_h + 1;
    }

    pr("relabel %d now h = %d\n", id(graph, sender), sender->h);
}

static node_t* other(node_t* u, edge_t* e)
{
	if (u == e->u)
		return e->v;
	else
		return e->u;
}

// Phase 1
static void decide(graph_t* graph, int i) {
	node_t* sender = currentWorkload[i]; // sändaren
	edge_t* edge = find_admissible_edge(sender); // Hitta en admissible edge
	// fprintf(stderr, "decide: node %ld (e=%d h=%d) -> edge=%p\n",
    //         sender - graph->v, sender->e, sender->h, (void*)edge);
	if(edge) {
		node_t* neighbour_receiver = other(sender, edge);

		int direction = findDirection(edge, sender);

		int pushAmount = f_pushAmount(edge, sender);

		decisionList[i] = (decision_t){
            .sender = sender,
            .receiver = neighbour_receiver,
            .edge = edge,
            .amount = pushAmount,
            .is_relabel = 0
        };
		// Vi har nu gjort ett val

    } else {
		// Vi hittade ingen, vi behöver relabela men vi gör det inte utan låter decisionträdet göra det åt oss.
        decisionList[i] = (decision_t){
            .sender = sender,
            .is_relabel = 1
        };
    }

}

int* queuedThisRound;   // g->n entries, all reset to 0 at start of each round

static void next_work_phase(graph_t* graph, node_t* u) {
    int idx = u - graph->v; // Hämta index av noden
	// fprintf(stderr, "  next_work_phase called for node %d, queued=%d\n", idx, queuedThisRound[idx]);

    if (!queuedThisRound[idx]) { // Lägg till i kön om vi inte har redan queat våran nod
        queuedThisRound[idx] = 1; // Sätt den till köad status
        nextWorkload[nextCount] = u; // Lägg i våran arbetslista
        nextCount++;
    }
}

//Phase 2:
static void apply_decision(graph_t* graph, decision_t* decision) {
	node_t* sender = decision->sender;

	if(decision->is_relabel) { // Om valet är att relabela
		relabel(graph, sender);              // <-- same logic, modulo locking
    	next_work_phase(graph, sender);
	} else {
		node_t* receiver = decision->receiver; // om vi inte relabela så kan vi ju äntligen "pusha", (vi ska inte pusha men vanligtvis ja)
		edge_t* edge = decision->edge;
		int pushAmountFromDecision = decision -> amount;

		if(sender == edge->u) {
			edge->f += pushAmountFromDecision;
		} else {
			edge->f -= pushAmountFromDecision;
		}
		int receiverWasEmpty = (receiver->e == 0);
		sender->e   -= pushAmountFromDecision;
		receiver->e += pushAmountFromDecision;

		// När vi är färdiga kan vi lägga undan till nästa runda, så länge vi inte är vid sänkan eller källan.
		node_t* source = graph -> s;
		node_t* tink = graph->t;
		if(receiverWasEmpty && receiver != source && receiver != tink) {
			next_work_phase(graph, receiver);
		}

		if(sender-> e > 0) {
			next_work_phase(graph, sender);
		}
	}
}


static void phase2_run(graph_t* graph) {
    for (int i = 0; i < currentCount; i++) {
        apply_decision(graph, &decisionList[i]);
    }
}

static void* createThreads(void* arg) {
	thread_args_t* t = (thread_args_t*) arg;
	graph_t* g = t->g; //hämta trådens graf
	int thread_id = t->thread_id;

	while(currentCount > 0) {
		pthread_barrier_wait(&barrier);

		for(int i = thread_id; i < currentCount; i+=N) { // Våran loadbalancing, varje tråd har sin egna uppgift, unik index
			decide(g, i);
		}
		pthread_barrier_wait(&barrier);

		if (pthread_barrier_wait(&barrier) == PTHREAD_BARRIER_SERIAL_THREAD) { // När alla trådar inväntar den sista, så får en av trådarna ett specialjobb och sedan låter vi den sista tråden jobba
            memset(queuedThisRound, 0, g->n * sizeof(int)); // Nollställ arrayen queuedThisRound i början av varje runda.
            nextCount = 0; // initiera

            for (int i = 0; i < currentCount; i++) {
                apply_decision(g, &decisionList[i]);
			}

            node_t** temp = currentWorkload;
            currentWorkload = nextWorkload;
            nextWorkload = temp;
			currentCount = nextCount;

			// fprintf(stderr, "=== round end: nextCount=%d, sink_e=%d ===\n", nextCount, g->t->e);
			// for (int k = 0; k < currentCount; k++) {
			// 	node_t* node = currentWorkload[k];
			// 	// fprintf(stderr, "  node %ld: e=%d h=%d\n", node - g->v, node->e, node->h);
			// }
		}

        pthread_barrier_wait(&barrier);
    }
	return NULL;
}
	
int preflow(graph_t* g)
{
	node_t*		s;
	node_t*		u;
	node_t*		v;
	edge_t*		e;
	list_t*		p;
	int		b;


	pthread_barrier_init(&barrier, NULL, N); // En pekare till klassen barrier så att vi kan utnyttja den
	init_phase_lists(g);
    //initiera höjden och allt annat
	s = g->s; // initiera källan
	s->h = g->n; //initiera höjden med antalet noder

	p = s->edge; // hämtar en lista av kanterna från källan

	/* start by pushing as much as possible (limited by
	 * the edge capacity) from the source to its neighbors.
	 *
	 */

	while (p != NULL) {
		e = p->edge;
		p = p->next;

		s->e += e->c;
		push(g, s, other(s, e), e, e->c);
	}

	// Vi behöver lägga ut antalet noder som vi ska bearbeta
	currentCount = 0;
	for (int i = 0; i < g->n; i++) { //Loopa genom alla noder i grafen
		node_t* u = &g->v[i]; // för varje nod i grafen
		if (u != g->s && u != g->t && u->e > 0) { // Om noden vi befinner oss i inte är källan eller sinkan, samt att vi har excess kvar
			currentWorkload[currentCount++] = u;  // Lägger vi till de i våran lista som ska bearbetas
		}
	}

	thread_args_t targs[N];
	for (int i = 0; i < N; i++) {
		targs[i].g = g;
        targs[i].thread_id = i;
    	pthread_create(&workers[i], NULL, createThreads, &targs[i]);
	}

	for (int i = 0; i < N; i++) {
		pthread_join(workers[i], NULL);
	}

	return g->t->e;
}

static void free_graph(graph_t* g)
{
	int		i;
	list_t*		p;
	list_t*		q;

	for (i = 0; i < g->n; i += 1) {
		p = g->v[i].edge;
		while (p != NULL) {
			q = p->next;
			free(p);
			p = q;
		}
	}
	free(g->v);
	free(g->e);
	free(g);
}

int main(int argc, char* argv[])
{
	FILE*		in;	/* input file set to stdin	*/
	graph_t*	g;	/* undirected graph. 		*/
	int		f;	/* output from preflow.		*/
	int		n;	/* number of nodes.		*/
	int		m;	/* number of edges.		*/

	progname = argv[0];	/* name is a string in argv[0]. */

	in = stdin;		/* same as System.in in Java.	*/

	n = next_int();
	m = next_int();

	/* skip C and P from the 6railwayplanning lab in EDAF05 */
	next_int();
	next_int();

	g = new_graph(in, n, m);

	fclose(in);

	f = preflow(g);

	printf("f = %d\n", f);

	free_graph(g);

	return 0;
}
