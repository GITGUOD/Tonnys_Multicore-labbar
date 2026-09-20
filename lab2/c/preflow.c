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

// Tillagd, trådkö
typedef struct {
    node_t* first;
	node_t* next;
    pthread_mutex_t lock; // lås
    pthread_cond_t nonempty; // condition variable
	int active;
} workqueue_t;

workqueue_t Q; // Delad kö med aktiva noder
pthread_t workers[N]; //trådar


struct node_t {
	int		h;	/* height.			*/
	int		e;	/* excess flow.			*/
	list_t*		edge;	/* adjacency list.		*/
	node_t*		next;	/* with excess preflow.		*/
    pthread_mutex_t lock;
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

void init_queue(workqueue_t* q) {
	pr("initiating queue");
    q-> first = NULL;
	q-> next = NULL;
	q->active = 0;
    pthread_mutex_init(&q->lock, NULL);
    pthread_cond_init(&q->nonempty, NULL);
}
// * är pekaren
// & för address
void queue_push(workqueue_t* q, node_t* u) {
	u->next = NULL;

	pr("pushing jobs to the queue \n");
    pthread_mutex_lock(&q->lock); //vi låser våran kö så att ingen kan modifiera
	// Om vi ska pusha något till en tom kö:
	if(q->next == NULL) {
		q->first = u;
		q->next = u; //vi gör den cirkulär
	} else {
		q-> next ->next = u;
		q -> next = u;
	}

	pthread_cond_signal(&q->nonempty); // Signalera någon tråd som väntar på att kön ska fyllas på
    pthread_mutex_unlock(&q->lock); // Låser upp så att andra trådar kan börja slåss
}


node_t* queue_pop(workqueue_t* q) {
	
	pr("Attempting to get the first job in the queue \n");

    pthread_mutex_lock(&q->lock); // Låsa
    while (q->first == NULL && q->active > 0) {// om det inte finns något jobb därav huvud == svansen men att vi har active threads
        pthread_cond_wait(&q->nonempty, &q->lock); //invänta
	}

	if (q->first == NULL) {          /* empty AND active == 0 -> done */
        pthread_mutex_unlock(&q->lock);
        return NULL;
    }
    node_t* u = q->first;
	q -> first = u -> next;
	//verifiera igen
	if (q->first == NULL) {
        q->next = NULL; /* kön blev tom */
    }
	q->active++;
    pthread_mutex_unlock(&q->lock); // låsa upp
    return u; // returnera den noden
}

/* Call this after a worker has fully discharged a node (u->e == 0). */
void queue_task_done(workqueue_t* q) {
	pr("Task done in the queue. \n");
    pthread_mutex_lock(&q->lock);
    q->active--;
    if (q->first == NULL && q->active == 0) {
        pthread_cond_broadcast(&q->nonempty);  /* wake everyone, not just one */
    }
    pthread_mutex_unlock(&q->lock);
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

    for (i = 0; i < n; i++) {
        pthread_mutex_init(&g->v[i].lock, NULL);
    }

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

static void push(graph_t* graph, node_t* sender, node_t* receiver, edge_t* edge)
{
	int		pushAmount;	/* remaining capacity of the edge. */

    node_t* first; // första låset
    node_t* second; // andra
	
    int sender_index = sender - (graph->v); // Här tar vi vad u pekar på och subtrahera vad v pekar på i g. -> säger att vi hämtar den variabeln i g.
    int receiver_index = receiver - (graph->v);

    // Vi vill bestämma vilken nod som är först och efter
    if (sender_index < receiver_index) {
        first = sender;
        second = receiver;
    } else {
        first = receiver;
        second = sender;
    }

	// Låsa våra noder så att ingen annan kan modifiera de
    pthread_mutex_lock(&first->lock);
    pthread_mutex_lock(&second->lock);

	// Dubbelkolla att kanten fortfarande går att pusha på
    int direction;

    if (sender == edge->u) {
        direction = 1;
    } else {
        direction = -1;
    }

    if (!(sender->h > receiver->h && direction * edge->f < edge->c)) {
        pthread_mutex_unlock(&second->lock);
        pthread_mutex_unlock(&first->lock);
        return;
    }

    // Nu vet vi att kanten fortfarande är giltig

	pr("push from %d to %d: ", id(graph, sender), id(graph, receiver));
	pr("f = %d, c = %d, so ", edge->f, edge->c);
	
	// vi kollar om nod u är samma som
	if (sender == edge->u) {
		pushAmount = MIN(sender->e, edge->c - edge->f);
		edge->f += pushAmount;
	} else {
		pushAmount = MIN(sender->e, edge->c + edge->f); // När vi gör sender -> e så hämtar vi excessen hos sändaren, men om vi gör edge -> f så hämtar vi flödet från kanten i klassen edge
		edge->f -= pushAmount;
	}

	pr("pushing %d\n", pushAmount);

	int receiverHasExcess = (receiver->e == 0); // Säkerställa att vi inte har pushat redan via att excessen ska vara 0 innan vi pushar

	sender->e -= pushAmount;
	receiver->e += pushAmount;

	/* the following are always true. */

	assert(pushAmount >= 0);
	assert(sender->e >= 0);
	assert(abs(edge->f) <= edge->c);

	if (receiverHasExcess && receiver != graph->s && receiver != graph->t) { //Om noden inte har varit aktiv och inte är källan eller sänkan så pushar vi till kön där trådarna kan arbeta
		queue_push(&Q, receiver);
	}
    pthread_mutex_unlock(&second->lock);
    pthread_mutex_unlock(&first->lock);

}


// static void relabel(graph_t* graph, node_t* sender)
// {
// 	pthread_mutex_lock(&sender->lock); //när vi ska relabala så låser vi våran variabel

// 	sender->h += 1;

// 	pr("relabel %d now h = %d\n", id(graph, sender), sender->h);

// 	pthread_mutex_unlock(&sender->lock); //när vi ska relabala så låser vi våran variabel
// }

static void relabel(graph_t* graph, node_t* sender)
{
    int minimum_h = INT_MAX;
    list_t* p = sender->edge;

	pthread_mutex_lock(&sender->lock);   // låset behövs bara för SKRIVNINGEN

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

		// Kolla rätt riktning
        if (residual > 0 && v->h < minimum_h) {
            minimum_h = v->h;
        }
    }

    if (minimum_h != INT_MAX) {
        sender->h = minimum_h + 1;
    }
    pthread_mutex_unlock(&sender->lock);

    pr("relabel %d now h = %d\n", id(graph, sender), sender->h);
}

static node_t* other(node_t* u, edge_t* e)
{
	if (u == e->u)
		return e->v;
	else
		return e->u;
}


/*
Våran worker class, hämtar en nod och börja discharga
*/
static void* worker(void* arg)
{
	graph_t* graph = (graph_t*) arg; // Vi vill kunna använda den grafen som används
    while (1) {
        node_t* u = queue_pop(&Q);
		if(u == NULL) { // Inget och köra, terminering
			break;
		}

        while (u->e > 0) {
            edge_t* edge = find_admissible_edge(u);
            if (edge)
                push(graph, u, other(u, edge), edge);   // ingen extra låsning här
            else
                relabel(graph, u);
        }
			queue_task_done(&Q);
    }
    printf("thread terminated\n");
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


    init_queue(&Q); // Initiera kön

    //initiera höjden och allt annat
	s = g->s;
	s->h = g->n;

	p = s->edge;

	/* start by pushing as much as possible (limited by
	 * the edge capacity) from the source to its neighbors.
	 *
	 */

	while (p != NULL) {
		e = p->edge;
		p = p->next;

		s->e += e->c;
		push(g, s, other(s, e), e);
	}

    // Lägg alla noder med excess i kön
    // for (int i = 0; i < g->n; i++) {
    //     node_t* u = &g->v[i];
    //     if (u != g->s && u != g->t && u->e > 0)
    //         queue_push(&Q, u);
    // }
	
	// Starta workers
    for (int i = 0; i < N; i++) {
        pthread_create(&workers[i], NULL, worker, g);
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
