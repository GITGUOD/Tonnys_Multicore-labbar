-module(preflow).
-export([preflow/0, node_loop/3]).

% set to 1 for debugging output
-define(PRINT, 0).

% preflow-push for undirected graph using actors.
%
% the nodes and a controller are actors and current flows are stored in a table (erlang ets)
% the edge records never change after reading from stdin
%
% the graph has an initial copy of the nodes but these are never updated and all changes to
% the nodes are done using recursion. so for instance, after a push, the excess is reduced in the node
% and since erlang is a functional language, the excess is not modified but instead a new node
% is returned from the push (and similar functions).
% 
% to know which actor to send a push to, say from U to V (integers), the record graph below has an
% array of actors indexed by node index.

-record(edge, { u, v, c }).

-record(node, { i, h, e, adj, source, sink, pending, neighbour_heights = [], parent = undefined, activeChildren = 0 }).	

% i:		index and only used for printing to see which node it is
% h:		height
% e:		excess preflow
% adj:		adjacency list of edge indices.

-record(graph, { n, m, nodes, edges, node_actors, flows }).
% 		n nodes and m edges stored in arrays. node_actors is also an
%		array. flows is a mutable table indexed by edge number and
%		containing the current flow counted from u to v.

pr(Format, Args) -> 
	case ?PRINT of
	1	-> io:format(Format, Args);
	_	-> 0
	end.

set_node_index(Nodes, N, N) -> Nodes;

set_node_index(Nodes, I, N) ->
	Node = array:get(I, Nodes),
	Node1 = Node#node{i = I},
	Nodes1 = array:set(I, Node1, Nodes),
	set_node_index(Nodes1, I+1, N).

mark_source_and_sink(Nodes, N) -> 
	Source = array:get(0, Nodes),
	Sink = array:get(N-1, Nodes),
	Nodes1 = array:set(0, Source#node{h = N, source = true }, Nodes),
	array:set(N-1, Sink#node{ sink = true }, Nodes1).

make_nodes(N) -> 
	Nodes = array:new(N, { default, #node{i = 0, h = 0, e = 0, adj = [], source = false, sink = false }}),
	Nodes1 = mark_source_and_sink(Nodes,N),
	set_node_index(Nodes1, 0, N).

make_edges(M) -> array:new(M, { default, #edge{u = 0, v = 0, c = 0 }}).

add_edge_to_node(Nodes, U, I) ->
	U0 = array:get(U, Nodes),
	#node{adj = Adj} = U0,
	U1 = U0#node{adj = [I|Adj]},
	array:set(U, U1, Nodes).

% read u,v,c for each edge from stdin and put Nodes and Edges in a graph when we have read all M edges.
read_edges(N, M, M, Nodes, Edges, T) -> #graph{n = N, m = M, nodes = Nodes, edges = Edges, flows = T};

read_edges(N, I, M, N0, E0,T) ->
	{ok,[U,V,C]} = io:fread("","~d ~d ~d"),
	E1 = array:set(I, #edge{u = U, v = V, c = C }, E0),
	N1 = add_edge_to_node(N0, U, I),
	N2 = add_edge_to_node(N1, V, I),
	ets:insert(T,{I,0}), % edge index I is a key and flow 0 is a value
	read_edges(N, I+1, M, N2, E1,T).

read_graph(N, M, Nodes, Edges) -> 
	T = ets:new(flows,[public,ordered_set]),
	read_edges(N, 0, M, Nodes, Edges, T).

other(U, Edge) -> 
	#edge{u = UU, v = VV } = Edge,
	case U of 
		UU -> VV;
		VV -> UU
	end.

node(G, I) ->
	#graph{nodes = Nodes } = G,
	array:get(I, Nodes).

edge(G, I) ->
	#graph{edges = Edges } = G,
	array:get(I, Edges).

edge_capacity(G, I) ->
	E = edge(G, I),
	#edge{ c = C } = E,
	C.

% get the actor for node U from the graph G
node_actor(G, U) ->
	#graph{node_actors = Node_actors } = G,
	array:get(U, Node_actors).

% how much can flow on edge I be increased by U?
available_capacity(G, U, I) ->

	Edge = edge(G, I),

	#edge{ u = UU, v = VV, c = C } = Edge,

	F = edge_flow(G,I),

	D = if 	
		U == UU -> C - F;
		U == VV -> C + F
	end,

	pr("=============== available capacity on ~p for ~p is ~p~n", [Edge, U, D]),

	D.  

print(G) ->
	case ?PRINT of
	1	-> 
			#graph{ n = N, m = M, nodes= Nodes, edges = Edges, node_actors = Node_actors } = G,
			pr("n = ~p~n", [N]),
			pr("m = ~p~n", [M]),
			pr("nodes = ~p~n", [array:to_list(Nodes)]),
			pr("edges = ~p~n", [array:to_list(Edges)]),
			pr("node_actors = ~p~n", [Node_actors]);
	_	-> 0
	end.

edge_flow(G,I) -> 
	#graph{flows = Flows } = G,
	pr("I=~p ~p~n", [I,ets:lookup(Flows, I)]),
	[{I,F}] = ets:lookup(Flows, I),
	pr("I=~p f=~p~n", [I,F]),
	F.

update_flow(G, I, U, D ) ->
	% U pushed D 
	Edge = edge(G,I),
	#edge{u = UU, v = VV } = Edge,
	#graph{flows = Flows } = G,
	[{I,F}] = ets:lookup(Flows, I),
	pr("D = ~p, F = ~p~n", [D, F]),
	case U of 
		UU -> ets:insert(Flows, {I,F+D});
		VV -> ets:insert(Flows, {I,F-D})
	end.

% Här börjar våran riktig implementation

% Om excess är 0 finns inget mer lokalt arbete att göra.
% % _C och _G är variabler som vi inte använder i denna pattern match
discharge(#node{e = 0} = Node, _C, _G) -> 
	% io:format("DISCHARGE FINISHED for node ~p (index ~p)~n", [Node, Node#node.i]),
	Node; % if pending är tom så slutar vi discharging

% Om alla edges har testats men excess finns kvar, relabela och börja om.
discharge(#node{pending = [], e = E, adj = Adj} = Node, C, G) when E > 0 ->
	Relabaled = relabeling(Node, G), % Påbörja relabeling
	Restart = Relabaled#node{pending = Adj, neighbour_heights = []}, % Töm pending listan eftersom vi har nya edges nu när vi har relabalat to all edges
	discharge(Restart, C, G); % Sedan kör vi discharge igen

% Slutligen om vi har en pendinglista, Testar nästa edge i pending-listan och skickar en push_request om kapacitet finns.
discharge(#node{pending = [I|Rest]} = Node, C, G) ->
	% Pushar till grannen om vi har kapacitet
	
	#node{i = U, e = E, h = Height} = Node, % hämtar våra variabler via pattern matching

	%hämtar edge, G är grafen och I är kanten, U är sändaren
	Edge = edge(G, I),

	%hämtar grannens index:
	V = other(U, Edge),

	%hämta tillgänglig kapacity
	Capacity = available_capacity(G, U, I),

	% Om vi har mer kapacitet att kunna ta emot
	case Capacity > 0 of
		true ->
			Amount = min(E, Capacity), % hur mycket vi kan pusha är min av excess och tillgänglig kapacitet

			Neighbour = node_actor(G, V), % hämtar grannens actor

			Neighbour ! { self(), push_request, U, I, Amount, Height}, % skickar push meddelande till grannen
			await_push_response(Node, C, G, Neighbour, I, Rest);
		false -> 
			UpdatedNode = Node#node{ pending = Rest }, % uppdaterar pending listan med resten av kanterna som vi inte har försökt pusha till än
			discharge(UpdatedNode, C, G) % vi försöker pusha igen med den uppdaterade noden
	end.


% % Väntar på svar på en push_request och uppdaterar nodens state.
% Kan samtidigt hantera inkommande push_requests från andra actors.
await_push_response(Node, C, G, Neighbour, I, Rest) ->
	#node{i = U, e = E} = Node, 

	receive
		{Neighbour, push_response, Admissible, AcceptedAmount, NeighbourHeight, NewlyEngaged} -> % Här tar vi emot grannens svar
			case Admissible of
				true -> % om grannen accepterar
					NewE = E - AcceptedAmount, % Uppdaterar sin grannes excess med det som accepterades
					% ange höjden på grannen i listan med grannars höjder
					NewNeighbourHeights = update_neighbour_height(Node#node.neighbour_heights, I, NeighbourHeight), % uppdaterar listan med grannars höjder
					
					pr("node ~p accepted push_response from ~p, Amount = ~p, NewE = ~p~n, NeighbourHeight = ~p", [Node, Neighbour, AcceptedAmount, NewE, NeighbourHeight]),
					
					% Ökar activeChildren vilket är aktiviteten eller så sagt: obesvarade push-förfrågningar
					NewActiveChildren =
						case NewlyEngaged of
							true  -> Node#node.activeChildren + 1;
							false -> Node#node.activeChildren
						end,
					pr("PUSH ACK node ~p: e ~p -> ~p, newlyEngaged=~p, activeChildren ~p -> ~p~n",
					[Node#node.i, E, NewE, NewlyEngaged,
						Node#node.activeChildren, NewActiveChildren]),
						
					NewUpdatedNode = Node#node{e = NewE, pending = Rest, neighbour_heights = NewNeighbourHeights, activeChildren = NewActiveChildren}, % returnerar en ny version av Node med uppdaterad excess
					discharge(NewUpdatedNode, C, G);
				false -> % om grannen inte accepterar
					pr("node ~p rejected push_response from ~p, Amount = ~p, NewE = ~p~n", [Node, Neighbour, AcceptedAmount, E]),
					
					NewNeighbourHeights = update_neighbour_height(Node#node.neighbour_heights, I, NeighbourHeight), % uppdaterar listan med grannars höjder

					UpdatedNode = Node#node{ pending = Rest, neighbour_heights = NewNeighbourHeights }, % uppdaterar pending listan med resten av kanterna som vi inte har försökt pusha till än

					discharge(UpdatedNode, C, G)
			end;
		{OtherSender, push_request, OtherU, OtherI, OtherAmount, OtherHeight} ->
        	{NewNode, _Accepted} = handle_push_request(Node, G, OtherSender, OtherU, OtherI, OtherAmount, OtherHeight), % Vi vill kunna hantera om vi har andra requests, då anropar vi rekursivt eftersom vi vill göra likadant med nästa request
			await_push_response(NewNode, C, G, Neighbour, I, Rest)
	end.


% Denna metoden är basically nodens hela beteende
% ör varje typ av meddelande jag kan få, vad ska jag göra med mitt nuvarande state,
% och vad blir mitt nya state innan jag går och väntar på nästa meddelande
node_loop(Node, C, G) ->
	% io:format("node_loop ALIVE for index ~p, excess ~p~n", [Node#node.i, Node#node.e]),


	pr("~s ~p: node = ~p~n", [?FUNCTION_NAME,?LINE,Node]),

	receive 
		{ C, hello } ->		pr("node ~p got hello~n", [Node]),
						C ! { self(), hello },
						node_loop(Node, C, G);
		
		{ Sender, push_request, U, I, Amount, Height} -> % Mottagaren tar vi emot push request från en granne.
			#node{adj = Adj, sink = Sink, source = Source} = Node, % hämtar ut mottagarens index, height och excess från node record
			{NewNode, _AcceptedAmount} = handle_push_request(Node, G, Sender, U, I, Amount, Height), % Hanterar mottagar push request
			case {Source, Sink} of
				{true, false} ->
					% Om returned excess har kommit fram till källan så behöver vi inte discharga den igen eftersom det går inte mer

					TerminationNode = potentiallyFinished(NewNode, C),
					node_loop(TerminationNode, C, G);

				{false, true} ->
					% Om vi är framme vid sinken så behöver vi inte discharga mer, vi vill kolla om vi är klara via termination check
					FinishedSink = finish_sink(NewNode),
					node_loop(FinishedSink, C, G);
				{false, false} ->
					case NewNode#node.e > 0 of  % Om vi inte är framme i någon av källan eller sinken, testar vi receiverns/current nodes excess
						true ->
							ActiveNode = NewNode#node{pending = Adj, neighbour_heights = []}, % nollställ pending list till alla edges and rensa neighbour_heights för att refresha processen då vi är på en ny nod
							FinishedNode = discharge(ActiveNode, C, G),
							TerminationNode = potentiallyFinished(FinishedNode, C),
							node_loop(TerminationNode, C, G);
						false ->
							node_loop(NewNode, C, G)
					end
			end;

		{_Child, termination_ack} ->
			pr("TERM ACK node ~p: outstanactiveChildrending ~p -> ~p, e=~p~n", [Node#node.i, Node#node.activeChildren, Node#node.activeChildren - 1, Node#node.e]),
			NewActiveChildren = Node#node.activeChildren - 1,

			UpdatedNode = Node#node{
				activeChildren = NewActiveChildren
			},

			TerminationNode = potentiallyFinished(UpdatedNode, C),

			node_loop(TerminationNode, C, G);


		{ Sender, start, NewG} ->	
			#node{ e = E, adj = Adj} = Node, % Läser ur en befintlig node och hämtar variablerna e, adj etc dvs de är bunden till excess fältet i våran node-record
			pr("node fick start, E = ~p, Adj = ~p~n", [E, Adj]),
			NewNode = case E > 0 of % här enligt vår logik, vill vi kolla på excess för att starta våran grej
				true -> SendingNode = Node#node{ pending = Adj, neighbour_heights = [] }, % ny version av node som sätter pending till hela adj listan för att markera starten på processen
						discharge(SendingNode, C, NewG);
				false -> Node
			end,
			TerminationNode = potentiallyFinished(NewNode, C),

			node_loop(TerminationNode, C, NewG);

		% den svarar tillbaka till Sender, men det är ett svar med excess-värdet
		{Sender, get_excess} ->
            #node{e = E} = Node,
            Sender ! {self(), E},
            node_loop(Node, C, G);

		Fel		->		erlang:exit(?LINE)
	end.

%
%Om en nod har excess kvar men ingen granne är admissible, måste noden relabelas.
%Då tittar vi på alla grannar som fortfarande har residualkapacitet, tar den minsta av deras senast kända heights och sätter vår egen height till minHeight + 1.
%Då blir åtminstone en av de grannarna möjlig att pusha till i nästa discharge-runda.
%
relabeling(#node{h = H, e = E, i = U, adj = Adj} = Node, G) -> 
	
	% Vi vill hitta den minsta höjden bland alla grannar som har tillgänglig kapacitet. Vi kan använda list comprehension för att filtrera grannarna och hämta deras höjder.
	case E > 0 of
		false ->
			Node; % Om excess är 0, returnera samma Node utan ändringar
		true ->
			% Vi vill hitta den minsta höjden bland alla grannar som har tillgänglig kapacitet. Vi kan använda list comprehension för att filtrera grannarna och h
			NeighbourHeights =
				lists:foldl(fun(I, Acc) ->
					Edge = edge(G, I),
					V = other(U, Edge),
					Capacity = available_capacity(G, U, I),
					if	Capacity > 0 -> % Om det finns tillgänglig kapacitet på kanten
							FoundHeight = lists:keyfind(I, 1, Node#node.neighbour_heights), % Letar efter information om kanten I i neighbour_heights
							case FoundHeight of
								{I, NeighbourHeight} -> [NeighbourHeight | Acc]; % Om den finns, hämta grannens height och packa in den i listan
								false -> Acc % Annars är listan tom eftersom acc inte hittar nästa ellement
							end;
						true -> Acc % Annars, om inget annat matchar, ignorera denna granne, true är som else i en if sats i erlang
					end
				end, [], Adj), % default värden

			% Om det finns några grannar med tillgänglig kapacitet utifrån våran sökning ovan
			case NeighbourHeights of
				[] -> Node; % Om det inte finns några grannar med tillgänglig kapacitet, returnera samma Node utan ändringar
				_  -> MinHeight = lists:min(NeighbourHeights), % Hitta den minsta höjden bland grannarna
					NewHeight = MinHeight + 1, % Sätt den nya höjden till minsta höjden + 1
				    % io:format("RELABEL node ~p: ~p -> ~p~n", [U, H, NewHeight]),
					Node#node{h = NewHeight} % Returnera en ny version av Node med uppdaterad höjd
			end
	end.

% Uppdaterar den sparade höjden för grannen som nås via edge I.
% Tar först bort eventuell gammal höjd och lägger sedan in den nya.
update_neighbour_height(NeighbourHeights, I, NeighbourHeight) ->
    Without = lists:keydelete(I, 1, NeighbourHeights),
    [{I, NeighbourHeight} | Without].

% Source kan vara färdig även om e > 0.
% Excess som inte kan nå sinken kan returneras till source.
% När source inte längre har något activeChildren arbete är computation klar.
potentiallyFinished(#node{i = I, source = true, activeChildren = 0} = Node, C) ->
    pr("SOURCE ~p COMPUTATION FINISHED~n", [I]),
	C ! {self(), computation_finished}, % skicka ett meddelande till processen C.
	Node;

% En vanlig nod är färdig när dess eget excess är 0 och den inte
% längre väntar på något arbete från sina children.
% Då skickar den termination_ack till sin parent.
potentiallyFinished(#node{i = I, e = 0, activeChildren = 0, parent = Parent} = Node, _C) when Parent =/= undefined ->
    pr("NODE ~p FINISHED -> ACK parent ~p~n", [I, Parent]),
	Parent ! {self(), termination_ack},
    Node#node{parent = undefined};

% Termination-villkoren är inte uppfyllda ännu, behåll noden oförändrad.
potentiallyFinished(Node, _C) ->
    Node.

% Sink är en terminal nod och behöver aldrig discharga sitt excess.
% Om sink har blivit aktiverad av en parent kan den därför direkt
% skicka tillbaka ett termination_ack för den grenen.
finish_sink(#node{parent = Parent} = Node) when Parent =/= undefined ->

    Parent ! {self(), termination_ack},
    Node#node{parent = undefined};

finish_sink(Node) ->
    Node.

% Hjöälpfunktion för att bestämma källan
set_source_excess(G) ->
	% Först måste vi hämta källnoden och dess excess, samt adj lista.
	#graph{nodes = Nodes} = G,
	SourceNode = array:get(0, Nodes),
	#node{adj = Adj} = SourceNode,
	% Sätter excess till summan av kapaciteterna på alla kanter som går ut från source
	TotalCapacity = lists:sum([edge_capacity(G, I) || I <- Adj]),
	UpdatedSourceNode = SourceNode#node{e = TotalCapacity},
	UpdatedNodes = array:set(0, UpdatedSourceNode, Nodes),
	G#graph{nodes = UpdatedNodes}.

% Handle_push_requests 
handle_push_request(Node, G, Sender, U, I, Amount, Height) ->
    #node{i = MyIndex, h = MyHeight, e = E, sink = Sink, parent = Parent, source = Source} = Node,

	% Kollar hur mycket kapacaitet den kan ta emot
    ReceiverCapacity =  available_capacity(G, U, I),
    AcceptedAmount = min(Amount, ReceiverCapacity), 

	SenderIsSource = (U == 0),
	% Kollar om vi kan pusha, om antingen vi får från källan eller om höjden är rätt, samt om vi kan acceptera 
    Admissible = (SenderIsSource orelse MyHeight == Height - 1) andalso (AcceptedAmount > 0),

    case Admissible of
        true ->
            NewE = E + AcceptedAmount, % Addera ihop både excessen, från den egna och från den ankommande

			% Om vi har en activation edge, vi vill sätta parent till den noden som skickade pushen. Om vi inte har en activation edge, vi behåller vår nuvarande parent.
			NewlyEngaged = (Parent == undefined) andalso (Source == false),

			NewParent =
				case NewlyEngaged of
					true  -> Sender;
					false -> Parent
				end,
			
			update_flow(G, I, U, AcceptedAmount), % Uppdatera flödesgrafen med de nya excesses

            NewNode = Node#node{e = NewE, parent = NewParent}, 
            Sender ! { self(), push_response, true, AcceptedAmount, MyHeight, NewlyEngaged },
            {NewNode, AcceptedAmount}; % skicka ett ACK tillbaka över dess status till sändaren
        false ->
            Sender ! { self(), push_response, false, 0, MyHeight, false },
            {Node, 0} % Skickar tillbaka att vi har ej tagit emot något
    end.

start_node_actor(G, N, N) -> G;

start_node_actor(G, I, N) ->
	A = node_actor(G, I),
	A ! { self(), start, G },
	start_node_actor(G, I+1, N). 

make_node_actor(G0, N, N) -> G0;

make_node_actor(G0, I, N) ->
	#graph { node_actors = A0 } = G0,
	Node = node(G0, I),
	Actor = spawn(preflow, node_loop, [Node, self(), G0]),
	A1 = array:set(I, Actor, A0),
	Actor ! { self(), hello },
	G1 = G0#graph { node_actors = A1 },
	make_node_actor(G1, I+1, N). 

count_node_actors(N,N) -> N;
count_node_actors(I,N) -> 
	pr("so far got ~p hello~n", [I]),
	receive 
		{ Node, hello } -> 
			pr("got hello from ~p~n", [Node]),
			count_node_actors(I+1, N)
	end.

make_actors(G0) ->
	#graph { n = N } = G0,
	Node_actors = array:new(N),
	G1 = G0#graph { node_actors = Node_actors },
	G2 = make_node_actor(G1, 0, N),
	count_node_actors(0, N),
	pr("all nodes said hello~n", []),
	print(G2),
	G2.

control(G0) ->
	#graph { n = N } = G0,

	G1 = make_actors(G0),

	S = node_actor(G1, 0),
	T = node_actor(G1, N-1),

	% start_node_actor(G1, 0, N-1), # Bug as it could send to others

	% decide when to print result and where to find it (either excess of sink or abs(excess of source))
	% good idea to enter a control_loop waiting for messages...
	% Fråga sink-aktorn om dess excess

	% timer:sleep(1000),
	% We got a synch issue because the other node actors could act before start has even finished giving out the flow numbers
	sync_start_others(G1, 1, N-1),

	S ! {self(), start, G1 },
	receive
		{S, computation_finished} ->
			T ! {self(), get_excess}
	end,

    % T ! {self(), get_excess},

    receive
        {T, Excess} ->
            io:format("f = ~p~n", [Excess])
    end.

% Om vi har grafen redan är stardad är det ok
sync_start_others(_G1, N, N) -> ok;

% Rekursiv funktion som startar och synkroniserar ALLA noder i grafen, en i taget,
% i ordningen I, I+1, I+2, ..., N-1.
% Syftet är att säkerställa att varje nod-aktör är igång och redo INNAN
% preflow-push-algoritmen sätter igång på riktigt (annars kan meddelanden
% skickas till processer som inte ens finns än).
sync_start_others(G1, I, N) ->
	A = node_actor(G1, I),
	A ! { self(), start, G1 },
	A ! { self(), get_excess },
	receive
		{A, _E} -> ok
	end,
	sync_start_others(G1, I+1, N).

preflow() -> 
	pr("preflow push in erlang~n", []),

	{ok,[N,M,_,_]} = io:fread("","~d ~d ~d ~d"),

	Nodes0 = make_nodes(N),
	E0 = make_edges(M),
	G0 = read_graph(N, M, Nodes0, E0),
	G1 = set_source_excess(G0), % Sätta source excess till summan av kapaciteterna på alla kanter som går ut från source därmed starta processen
	print(G1),

	control(G1).