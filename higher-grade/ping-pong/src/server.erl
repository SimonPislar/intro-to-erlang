%% @doc A server that keeps track of  <a target="_blank"
%% href="https://www.rd.com/culture/ablaut-reduplication/">ablaut
%% reduplication</a> pairs. You should implement two versions of the server. One
%% stateless server and one stateful server.
%%
%% <ul>
%% <li>
%% The stateless server keeps
%% track of a static number of ablaut reduplication pairs. Each pair is handled
%% by a separate message receive pattern.
%% </li>
%% <li>
%% The stateful server keeps
%% track of dynamic number of ablaut reduplication pairs using a <a
%% target="_blank" href="https://erlang.org/doc/man/maps.html">Map</a>.
%% </li>
%% </ul>
%% <p>
%% You should also implement process supervision of the server.
%% <ul>
%% <li>
%% The supervisor should <a target="_blank"
%% href="https://erlang.org/doc/reference_manual/processes.html#registered-processes">register</a>
%% the server process under the name `server'.
%% </li>
%% <li>
%% The name of a registered process can be used instead of the Pid when sending
%% messages to the process.
%% </li>
%% <li>
%% The supervisor should restart the server if the server terminates due to an
%% error.
%% </li>
%% </ul>
%% </p>

-module(server).
-export([start/2, update/0, update/1, stop/0, stop/1, loop/0, loop/1]).

%% @doc The initial state of the stateful server.

-spec pairs() -> map().

pairs() ->
    #{  ping => pong,
        tick => tock,
        hipp => hopp,
        ding => dong,
        queen => kong}.

%% @doc Starts the server.

-spec start(Stateful, Supervised) -> Server when
    Stateful :: boolean(),
    Supervised :: boolean(),
    Server :: pid().

start(false, false) ->
    spawn(fun() -> loop() end);
start(false, true) ->
    spawn(fun() -> supervisor(false) end);
start(true, false) ->
    spawn(fun() -> loop(pairs()) end);
start(true, true) ->
    spawn(fun() -> supervisor(true) end).

%% @doc The server supervisor. The supervisor must trap exit, spawn the server
%% process, link to the server process and wait the server to terminate. If the
%% server terminates due to an error, the supervisor should make a recursive
%% call to it self to restart the server.

-spec supervisor(Stateful) -> ok when
    Stateful :: boolean().

supervisor(Stateful) ->
    process_flag(trap_exit, true),
    case Stateful of
        true  ->
            PID = spawn_link(fun () -> loop(pairs()) end),
            %%register(server, PID),
            link(PID);
        %supervisor_loop(PID, Stateful);
        false ->
            PID = spawn_link(fun () -> loop() end),
            %%register(server, PID),
            link(PID)
        %supervisor_loop(PID, Stateful)
    end,
    supervisor_loop(Stateful, PID).

supervisor_loop(Stateful, Server) ->
    receive
        {'EXIT', P, R} ->
            io:format("Process ~p terminated with reason ~w!~n", [P, R]),
            if R == normal ->
                ok;
                true ->
                    supervisor(Stateful)
            end;
        {ping, Ping, From} ->
            Server ! {ping, Ping, From},
            supervisor_loop(Stateful, Server);
        {put, Ping, Pong, From} ->
            Server ! {put, Ping, Pong, From},
            supervisor_loop(Stateful, Server);
        {update, From} ->
            Server ! {update, From},
            supervisor_loop(Stateful, Server);
        {stop, From} ->
            Server ! {stop, From},
            supervisor_loop(Stateful, Server)
    end.

%% @doc Terminates the supervised server.

-spec stop() -> ok | error.

stop() ->
    stop(server).

-spec stop(Server) -> ok | error when
    Server :: pid().

%% @doc Terminates the unsupervised server.

stop(Server) ->
    Server ! {stop, self()},
    receive
        {stop, ok} ->
            ok;
        Msg ->
            io:format("stop/1: Unknown message: ~p~n", [Msg]),
            error
    end.

%% @doc Makes the supervised server perform a hot code swap.

-spec update() -> ok | error.

update() ->
    update(server).

%% @doc Makes the unsupervised server perform a hot code swap.

-spec update(Server) -> ok | error when
    Server :: pid().

update(Server) ->
    Server ! {update, self()},
    receive
        {update, ok} ->
            ok;
        Msg ->
            io:format("update/1: Unknown message: ~p~n", [Msg]),
            error
    end.

%% @doc The process loop for the stateless server. The stateless server keeps
%% track of a static number of ablaut reduplication pairs. Each pair is handled
%% by a separate message receive pattern.

-spec loop() -> {stop, ok}.

loop() ->
    receive
        {ping, blipp, From} ->
            exit(simulated_bug),
            From ! {pong, blopp},
            loop();
        {ping, ding, From} ->
            From ! {pong, dong},
            loop();
        {ping, ping, From} ->
            From ! {pong, pong},
            loop();
        {ping, queen, From} ->
            From ! {pong, kong},
            loop();
        {ping, tick, From} ->
            From ! {pong, tock},
            loop();
        {stop, From} ->
            From ! {stop, ok};
        {update, From}  ->
            From ! {update, ok},
            server:loop();
        Msg ->
            io:format("loop/0: Unknown message: ~p~n", [Msg]),
            loop()
    end.


%% @doc The process loop for the statefull server. The stateful server keeps
%% track of dynamic number of ablaut reduplication pairs using a <a
%% target="_blank" href="https://erlang.org/doc/man/Pairss.html">Map</a>.

-spec loop(Pairs) -> {stop, ok} when
    Pairs :: map().

loop(Pairs) ->
    receive
        {ping, flip, _From} ->
            %%From ! {pong, flop}, %%Test update with this
            %%loop(Pairs);
            exit(simulated_bug);
        {ping, Ping, From} ->
            %% send correct reply.
            case maps:find(Ping, Pairs) of
                {ok, Value} ->
                    From ! {pong, Value};
                error ->
                    exit(unknown_message)
            end,
            loop(Pairs);
    %% Handle the update, put and stop actions.
        {update, From}  -> %%TODO: fix
            %% Trigger a hot code swap.
            From ! {update, ok},
            server:loop(Pairs);
        {put, Ping, Pong, From} ->
            From ! {put, Ping, Pong, ok},
            Pairs2 = maps:put(Ping,Pong, Pairs),
            loop(Pairs2);
        {stop, From} ->
            From ! {stop, ok};
        Msg ->
            io:format("loop2/0: Unknown message: ~p~n", [Msg]),
            loop(Pairs)
    end.
