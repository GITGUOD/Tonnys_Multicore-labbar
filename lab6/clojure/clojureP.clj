(require '[clojure.string :as str])		; for splitting an input line into words
; require is import, use functions like str/split

(def debug false) ; global boolean

(defn prepend [list value] (cons value list))	; put value at the front of list
;; Syntax: (cons head tail) returns a new sequence with 'head' as the first element


(defrecord node [i e h adj])			; index excess-preflow height adjacency-list
;; Defining immutable record type 'node' with fields:
;;   i   : Node index (0 to n-1)
;;   e   : Excess preflow currently sitting at this node
;;   h   : Height label for push-relabel algorithm
;;   adj : Linked list of edge indices connected to this node

(defn node-adj [u] (:adj u))			; get the adjacency-list of a node
;;   │         │     └─ Body expression (executes and returns value)
;;   │         └────── Input parameter vector (takes node 'u')
;;   └──────────────── Function name

;; Example
;;Clojure
;; (defn add-five [x]
;;   (+ x 5))  ;; <-- THIS IS THE BODY

; ':' stands for keyword

(defn node-height [u] (:h u))			; get the height of a node
(defn node-excess [u] (:e u))			; get the excess-preflow of a node
;; getters

;; Helper: Checks if node at index 'u' in vector 'nodes' has excess flow (> 0)
;; '@(nodes u)' dereferences the Ref storing the node record at index 'u'
(defn has-excess [u nodes]
	(> (node-excess @(nodes u)) 0))

(defrecord edge [u v f c])			; one-node another-node flow capacity
(defn edge-flow [e] (:f e))			; get the current flow on an edge
(defn edge-capacity [e] (:c e))			; get the capacity of an edge

; read the m edges with the normal format "u v c"

;; Recursively reads 'm' edges from STDIN and populates the global 'nodes' and 'edges' vectors
;; Parameters:
;;   i     : Current edge index being processed (0 to m-1)
;;   m     : Total number of edges to read
;;   nodes : Vector of Refs holding node records
;;   edges : Vector of Refs holding edge records
(defn read-graph [i m nodes edges]
	(if (< i m)
		(do	(let [line 	(read-line)]		 	
			(let [words	(str/split line #" ") ]

			(let [u		(Integer/parseInt (first words))]
			(let [v 	(Integer/parseInt (first (rest words)))]
			(let [c 	(Integer/parseInt (first (rest (rest words))))]
			
			(ref-set (edges i) (update @(edges i) :u + u))
			(ref-set (edges i) (update @(edges i) :v + v))
			(ref-set (edges i) (update @(edges i) :c + c))

			(ref-set (nodes u) (update @(nodes u) :adj prepend i))
			(ref-set (nodes v) (update @(nodes v) :adj prepend i)))))))

			; read remaining edges
			(recur (+ i 1) m nodes edges))))


;; ref (The Safe): Creates the empty safe and puts an initial value inside.

;; @ (Looking Through the Glass): Reads whatever is currently inside without unlocking or touching anything.

;; ref-set (Unlocking & Replacing): Replaces the contents inside the safe with a brand new item (must be done inside a dosync transaction).

(defn other [edge u]
	(if (= (:u edge) u) (:v edge) (:u edge)))

(defn debug-print [& args]
  (when debug
    (binding [*out* *err*]
      (apply println args))))

(defn u-is-edge-u [edge u]
	(= (:u edge) u))

(defn increase-flow [edges i d]
	(ref-set (edges i) (update @(edges i) :f + d)))
; öka flödes med d

(defn decrease-flow [edges i d]
	(ref-set (edges i) (update @(edges i) :f - d)))

; minska flödet med d

(defn move-excess [nodes u v d]
	(ref-set (nodes u) (update @(nodes u) :e - d))
	(ref-set (nodes v) (update @(nodes v) :e + d)))
; flytta excess

(defn insert [excess-nodes v]
	(ref-set excess-nodes (cons v @excess-nodes)))
; inserta excess i listan av nbr of excess

(defn check-insert [excess-nodes v s t]
	(if (and (not= v s) (not= v t))
		(insert excess-nodes v)))

(defn push [edge-index u nodes edges excess-nodes change s t]
	(let [ed   @(edges edge-index) ; edges/index
	      v    (other ed u) ; receivern
	      uh   (node-height @(nodes u)) ; u:s höjd
	      vh   (node-height @(nodes v)) ; v;s höjd
	      e    (node-excess @(nodes u)) ; excess
	      f    (edge-flow ed) ; flöde
	      c    (edge-capacity ed) ; kapacitet
	      b    (if (u-is-edge-u ed u) 1 -1) ; riktning La till detta och neråt
	      d    (min e (- c (* b f))) ; så mycket flöde vi kan skicka iväg
	      v-was-empty (= (node-excess @(nodes v)) 0)] ; om mottgarens excess är tom

	(if (> b 0) ; om vi ska skicka flödes framåt
		(increase-flow edges edge-index d)
		(decrease-flow edges edge-index d))
	(move-excess nodes u v d) ; flyttar på excessen
	(when v-was-empty (check-insert excess-nodes v s t)) ; (when villkor gör-detta). Om v-was-empty är sant läggs v i kön, annars händer ingenting så att vi inte jobbar med den

	(if debug
		(do
			(debug-print "--------- push -------------------")
			;; (println "i = " i)
			(debug-print "u = " u)
			(debug-print "uh = " uh)
			(debug-print "e = " e)
			(debug-print "f = " f)
			(debug-print "c = " c)
			(debug-print "v = " v)
			(debug-print "vh = " vh)
			(debug-print "d = " d)
			(debug-print "v-was-empty = " v-was-empty)
			))))


; go through adjacency-list of source and push
(defn initial-push [adj s t nodes edges excess-nodes]
	(let [change (ref 0)] ; unused for initial pushes since we know they will be performed
	(if (not (empty? adj))
		(do 
			; give source this capacity as excess so the push will be accepted
			(ref-set (nodes s) (update @(nodes s) :e + (edge-capacity @(edges (first adj))))) ; same as: s->e += e->c
			(push (first adj) s nodes edges excess-nodes change s t)
			(initial-push (rest adj) s t nodes edges excess-nodes)))))

;; Clojure code reads from the inside out, and (f a b c) means “call f with a, b and c”. Here is the line:
;; (first adj) takes the first element of the list adj. That’s an edge index, say i.
;; (edges i) gets element i of the vector edges. A vector can be called like a function with an index. The element is a ref, a mutable box holding an edge.
;; @ is short for (deref ...). It opens the box and gives you the value inside, here the edge record. So @(edges i) is the edge itself.
;; (edge-capacity ...) is your helper that returns (:c edge), the capacity.

(defn initial-pushes [nodes edges s t excess-nodes]
	(initial-push (node-adj @(nodes s)) s t nodes edges excess-nodes))

(
	defn can-push? [u i nodes edges]
		(let	[
					edge @(edges i)
					v (other edge u)
					direction (if (u-is-edge-u edge u) 1 -1)
					u-height (node-height @(nodes u)) ; @ is read only
					v-height (node-height @(nodes v))
					room-left (< (* direction (edge-flow edge)) (edge-capacity edge)) ; check if there is room left by checking if capacity is bigger than the current flow
				]

			(
				and (> u-height v-height) room-left ;; (> u-height v-height) is identical to u-height > v-height.
				; also this is a check that both are true, else we need to relabel japp
			)
		
		)
)

(
	defn find-edge-to-push [u nodes edges]
		(
			loop
				[remaining (node-adj @(nodes u))]
					(
						cond
							(empty? remaining) nil
							(can-push? u (first remaining) nodes edges) (first remaining)
							:else (recur (rest remaining))
					)

		)
)

(defn relabel [u nodes]
	(debug-print "relabel" u)
	(ref-set (nodes u) (update @(nodes u) :h inc))) ; inc stands for increment

; do one push or one relabel for u
(defn discharge [u nodes edges excess-nodes s t]
	(debug-print "discharge" u)
	(let [i (find-edge-to-push u nodes edges)] ; hittar en kant att pusha
		(if (nil? i) ; om tomt
			(relabel u nodes) ; relabela
			(push i u nodes edges excess-nodes (ref 0) s t)) ; sen pusha
		(when (has-excess u nodes) ; om det finns excess kvar
			(insert excess-nodes u)))) ; kasta excess till nästa

(defn remove-any [excess-nodes]
	(dosync 
		(let [ u (ref -1)]
			(do
				(if (not (empty? @excess-nodes))
					(do
						(ref-set u (first @excess-nodes))
						(ref-set excess-nodes (rest @excess-nodes))))
			@u))))

; read first line with n m c p from stdin

(def line (read-line))

; split it into words
(def words (str/split line #" "))

(def n (Integer/parseInt (first words)))
(def m (Integer/parseInt (first (rest words))))

(def s 0)
(def t (- n 1))
(def excess-nodes (ref ()))

(def nodes (vec (for [i (range n)] (ref (->node i 0 (if (= i 0) n 0) '())))))

(def edges (vec (for [i (range m)] (ref (->edge 0 0 0 0)))))

(dosync (read-graph 0 m nodes edges))

(defn worker [] 
    (loop []
		(let [u (remove-any excess-nodes)] ; Så länge vi har excess kvar
			(debug-print "got" u "queue" @excess-nodes)
			(when (not= u -1) ; om nod u inte lika med -1, alltså att det inte finns flera processer kvar, då kan vi sluta
				(dosync (discharge u nodes edges excess-nodes s t))
				(recur))))
)

(defn preflow []

	(dosync (initial-pushes nodes edges s t excess-nodes))

	(let [workers (doall (for [_ (range 4)] (future (worker))))] ; Normalt, när du skriver (worker), stannar programmet och väntar tills worker är klar. Med future runt startar jobbet i bakgrunden och programmet går vidare direkt. många Clojure-funktioner, bland annat for, map och filter, är lata (lazy). De räknar inte ut något förrän någon faktiskt behöver värdena. Nu skrivs “hej 0”, “hej 1”, “hej 2” ut direkt, för doall går igenom hela sekvensen och beräknar alla element. Sedan returnerar den sekvensen.
	(doseq [w workers] @w)) ; invänta tills alla workers är färdiga, doseq är basically en loop så att vi slipper skriva @w fyra gånger.
	(debug-print "ALL WORKERS DONE")
	(println "f =" (node-excess @(nodes t))))

(preflow)
(shutdown-agents)

;; • Completes active work: Any agent actions currently running are allowed to finish their execution.
;; • Rejects new actions: No new actions are accepted or processed by the thread pool after it is called.
;; • Allows JVM shutdown: Clojure's agent system uses non-daemon background threads that will otherwise prevent the Java Virtual Machine (JVM) from exiting; calling shutdown-agents terminates these threads so the process can cleanly exit.