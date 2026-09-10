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

-record(node, { i, h, e, adj, source, sink, pending, neighbour_heights = [], parent = undefined, outstanding = 0 }).	

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

% discharge tries to push but never waits.
% discharge(Node, C, G, []) -> Node; Old version of discharge, now we want to keep track of pending nodes to push to
discharge(#node{e = 0} = Node, _C, _G) -> 
	% io:format("DISCHARGE FINISHED for node ~p (index ~p)~n", [Node, Node#node.i]),
	Node; % if pending är tom så slutar vi discharging

% discharge(Node, C, G) when Node#node.e > 0 -> % if excess is greater than 0 and we tried every edge, we need to relabel the node and restart discharge
discharge(#node{pending = [], e = E, adj = Adj} = Node, C, G) when E > 0 ->
	Relabaled = relabeling(Node, G), % relabeling returns a new node with updated height
	Restart = Relabaled#node{pending = Adj, neighbour_heights = []}, % we reset the pending list to all edges and clear the neighbour_heights list as we are to have a fresh start
	discharge(Restart, C, G); % we restart the discharge with the relabeled node and the same graph

% discharge(Node, C, G, [I|Adj]) ->
discharge(#node{pending = [I|Rest]} = Node, C, G) -> % pending is a list of edges to push to, we take the first one and try to push excess along it
	
	#node{i = U, e = E, h = Height} = Node, % variabelnamnet måste alltid börja med en stor bokstav
	% här plockar vi ut noderna U och E från Node recordet, dvs index och excess.

	%hämtar edge:
	Edge = edge(G, I),

	%hämtar grannens index:
	V = other(U, Edge),

	%hämta tillgänglig kapacity
	Capacity = available_capacity(G, U, I),

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


% Nu behöver vi logik för att hantera grannens svar:
await_push_response(Node, C, G, Neighbour, I, Rest) ->
	#node{i = U, e = E} = Node, 

	receive
		{Neighbour, push_response, Admissible, AcceptedAmount, NeighbourHeight, NewlyEngaged} -> % Här tar vi emot grannens svar
			case Admissible of
				true -> % om grannen accepterar
					NewE = E - AcceptedAmount, % Uppdaterar sin grannes excess med det som accepterades
					% ange höjden på grannen i listan med grannars höjder
					NewNeighbourHeights = update_neighbour_height(Node#node.neighbour_heights, I, NeighbourHeight), % uppdaterar listan med grannars höjder
					% updatera flödet i grafen
					% update_flow(G, I, U, AcceptedAmount), % uppdaterar flödet i grafen
					pr("node ~p accepted push_response from ~p, Amount = ~p, NewE = ~p~n, NeighbourHeight = ~p", [Node, Neighbour, AcceptedAmount, NewE, NeighbourHeight]),
					NewOutstanding =
						case NewlyEngaged of
							true  -> Node#node.outstanding + 1;
							false -> Node#node.outstanding
						end,
					pr("PUSH ACK node ~p: e ~p -> ~p, newlyEngaged=~p, outstanding ~p -> ~p~n",
					[Node#node.i, E, NewE, NewlyEngaged,
						Node#node.outstanding, NewOutstanding]),
						
					NewUpdatedNode = Node#node{e = NewE, pending = Rest, neighbour_heights = NewNeighbourHeights, outstanding = NewOutstanding}, % returnerar en ny version av Node med uppdaterad excess
					discharge(NewUpdatedNode, C, G);
				false -> % om grannen inte accepterar
					pr("node ~p rejected push_response from ~p, Amount = ~p, NewE = ~p~n", [Node, Neighbour, AcceptedAmount, E]),
					% Vi behöver relabela noden eftersom vi inte kunde pusha till grannen och kunde ej hitta någon annan granne
					% Rebaled = relabeling(Node, G), % vi relabelar noden innan vi börjar pusha
					% Problem, vi vet inte om alla grannar inte funkar efter 1 rejection
					% ange höjden på grannen i listan med grannars höjder
					NewNeighbourHeights = update_neighbour_height(Node#node.neighbour_heights, I, NeighbourHeight), % uppdaterar listan med grannars höjder

					% Vi behöver uppdatera pending listan med resten av kanterna som vi inte har försökt pusha till än
					UpdatedNode = Node#node{ pending = Rest, neighbour_heights = NewNeighbourHeights }, % uppdaterar pending listan med resten av kanterna som vi inte har försökt pusha till än

					discharge(UpdatedNode, C, G) % vi försöker pusha igen med den relabelade noden
			end;
		{OtherSender, push_request, OtherU, OtherI, OtherAmount, OtherHeight} ->
        	{NewNode, _Accepted} = handle_push_request(Node, G, OtherSender, OtherU, OtherI, OtherAmount, OtherHeight),
			await_push_response(NewNode, C, G, Neighbour, I, Rest)
	end.

	% UpdatedNode = Node#node{ pending = Rest }, % uppdaterar pending listan med resten av kanterna som vi inte har försökt pusha till än
	% UpdatedNode.

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
		% Syntax skäl: Order måste vara samma som i discharge, dvs vi skickar push_request med U, I, Amount, Height.
		{ Sender, push_request, U, I, Amount, Height} -> % Mottagaren tar vi emot push request från en granne.
			#node{adj = Adj, sink = Sink, source = Source} = Node, % hämtar ut mottagarens index, height och excess från node record
			{NewNode, _AcceptedAmount} = handle_push_request(Node, G, Sender, U, I, Amount, Height),
			case {Source, Sink} of
				{true, false} ->
					% Returned excess reached the source.
					% Source does not discharge it again.
					TerminationNode = potentiallyFinished(NewNode, C),
					node_loop(TerminationNode, C, G);

				{false, true} ->
					FinishedSink = finish_sink(NewNode),
					node_loop(FinishedSink, C, G);
				{false, false} ->
					case NewNode#node.e > 0 of  % check NewNode's excess, not the old E
						true ->
							ActiveNode = NewNode#node{pending = Adj, neighbour_heights = []}, % reset pending list to all edges and clear neighbour_heights for a fresh start
							FinishedNode = discharge(ActiveNode, C, G),
							TerminationNode = potentiallyFinished(FinishedNode, C),
							node_loop(TerminationNode, C, G);
						false ->
							node_loop(NewNode, C, G)
					end
			end;

		{_Child, termination_ack} ->
			pr("TERM ACK node ~p: outstanding ~p -> ~p, e=~p~n",
			[Node#node.i,
			Node#node.outstanding,
			Node#node.outstanding - 1,
			Node#node.e]),
			NewOutstanding = Node#node.outstanding - 1,

			UpdatedNode = Node#node{
				outstanding = NewOutstanding
			},

			TerminationNode = potentiallyFinished(UpdatedNode, C),

			node_loop(TerminationNode, C, G);

		% Sender ! { self(), push_response, Admissible, AcceptedAmount } -> % skickar svar till grannen om jag accepterade pushen eller inte

		% My edit
		% this is a tuple
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

		{Sender, get_excess} ->
            #node{e = E} = Node,
            Sender ! {self(), E},
            node_loop(Node, C, G);

		Fel		->		erlang:exit(?LINE)
	end.

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
							case lists:keyfind(I, 1, Node#node.neighbour_heights) of
								{I, NeighbourHeight} -> [NeighbourHeight | Acc];
								false -> Acc  % no live info for this edge yet
							end;
						true -> Acc % Annars, ignorera denna granne
					end
				end, [], Adj),
			% Om det finns några grannar med tillgänglig kapacitet
			case NeighbourHeights of
				[] -> Node; % Om det inte finns några grannar med tillgänglig kapacitet, returnera samma Node utan ändringar
				_  -> MinHeight = lists:min(NeighbourHeights), % Hitta den minsta höjden bland grannarna
					NewHeight = MinHeight + 1, % Sätt den nya höjden till minsta höjden + 1
				    % io:format("RELABEL node ~p: ~p -> ~p~n", [U, H, NewHeight]),
					Node#node{h = NewHeight} % Returnera en ny version av Node med uppdaterad höjd
			end
	end.

update_neighbour_height(NeighbourHeights, I, NeighbourHeight) ->
    Without = lists:keydelete(I, 1, NeighbourHeights),
    [{I, NeighbourHeight} | Without].

% its ok that e > 0 because flow that cannot reach the sink may return to the source.
potentiallyFinished(#node{i = I, source = true, outstanding = 0} = Node, C) ->
    pr("SOURCE ~p COMPUTATION FINISHED~n", [I]),
	C ! {self(), computation_finished},
	Node;

potentiallyFinished(#node{i = I, e = 0, outstanding = 0, parent = Parent} = Node, _C) when Parent =/= undefined ->
    pr("NODE ~p FINISHED -> ACK parent ~p~n", [I, Parent]),
	Parent ! {self(), termination_ack},
    Node#node{parent = undefined};

potentiallyFinished(Node, _C) ->
    Node.

finish_sink(#node{parent = Parent} = Node) when Parent =/= undefined ->

    Parent ! {self(), termination_ack},
    Node#node{parent = undefined};

finish_sink(Node) ->
    Node.

% Helper for deciding which node to start with
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

% Helper method for pushing
handle_push_request(Node, G, Sender, U, I, Amount, Height) ->
    #node{i = MyIndex, h = MyHeight, e = E, sink = Sink, parent = Parent, source = Source} = Node,

    ReceiverCapacity =  available_capacity(G, U, I),
    AcceptedAmount = min(Amount, ReceiverCapacity), 

	% Initial push should be from source, so we can accept it even if our height is not one less than the sender's height.
	SenderIsSource = (U == 0),
	% Vi måste bestämma om vi kan acceptera pushen baserat på höjden på grannen och vår egen höjd.
    Admissible = (SenderIsSource orelse MyHeight == Height - 1) andalso (AcceptedAmount > 0),

    case Admissible of
        true ->
            NewE = E + AcceptedAmount,

			% Om vi har en activation edge, vi vill sätta parent till den noden som skickade pushen. Om vi inte har en activation edge, vi behåller vår nuvarande parent.
			NewlyEngaged = (Parent == undefined) andalso (Source == false),

			NewParent =
				case NewlyEngaged of
					true  -> Sender;
					false -> Parent
				end,
			
			update_flow(G, I, U, AcceptedAmount),

            NewNode = Node#node{e = NewE, parent = NewParent},
            Sender ! { self(), push_response, true, AcceptedAmount, MyHeight, NewlyEngaged },
            {NewNode, AcceptedAmount};
        false ->
            Sender ! { self(), push_response, false, 0, MyHeight, false },
            {Node, 0}
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

	start_node_actor(G1, 0, N-1),

	% decide when to print result and where to find it (either excess of sink or abs(excess of source))
	% good idea to enter a control_loop waiting for messages...
	% Fråga sink-aktorn om dess excess
	% timer:sleep(1000),
	receive
		{S, computation_finished} ->
			T ! {self(), get_excess}
	end,

    % T ! {self(), get_excess},

    receive
        {T, Excess} ->
            io:format("f = ~p~n", [Excess])
    end.



preflow() -> 
	pr("preflow push in erlang~n", []),

	{ok,[N,M,_,_]} = io:fread("","~d ~d ~d ~d"),

	Nodes0 = make_nodes(N),
	E0 = make_edges(M),
	G0 = read_graph(N, M, Nodes0, E0),
	G1 = set_source_excess(G0), % Sätta source excess till summan av kapaciteterna på alla kanter som går ut från source därmed starta processen
	print(G1),

	control(G1).