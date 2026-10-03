-module(chat_ffi).

-export([
    listen/1,
    accept/1,
    connect/2,
    send_line/2,
    recv_line/1,
    close/1,
    timestamp/0,
    getenv/1,
    sleep/1
]).

listen(Port) ->
    Options = [binary, {packet, line}, {active, false}, {reuseaddr, true}],
    case gen_tcp:listen(Port, Options) of
        {ok, Socket} -> {ok, Socket};
        {error, Reason} -> {error, reason(Reason)}
    end.

accept(ListenSocket) ->
    case gen_tcp:accept(ListenSocket) of
        {ok, Socket} -> {ok, Socket};
        {error, Reason} -> {error, reason(Reason)}
    end.

connect(Host, Port) ->
    Options = [binary, {packet, line}, {active, false}],
    case gen_tcp:connect(binary_to_list(Host), Port, Options) of
        {ok, Socket} -> {ok, Socket};
        {error, Reason} -> {error, reason(Reason)}
    end.

send_line(Socket, Line) ->
    case gen_tcp:send(Socket, [Line, <<"\n">>]) of
        ok -> nil;
        {error, _} -> nil
    end.

recv_line(Socket) ->
    case gen_tcp:recv(Socket, 0) of
        {ok, Data} ->
            {ok, unicode:characters_to_binary(string:trim(binary_to_list(Data)))};
        {error, Reason} ->
            {error, reason(Reason)}
    end.

close(Socket) ->
    gen_tcp:close(Socket),
    nil.

timestamp() ->
    Now = erlang:system_time(millisecond),
    unicode:characters_to_binary(
        calendar:system_time_to_rfc3339(Now, [{unit, millisecond}, {offset, "Z"}])
    ).

getenv(Name) ->
    case os:getenv(binary_to_list(Name)) of
        false -> <<>>;
        Value -> unicode:characters_to_binary(Value)
    end.

sleep(Milliseconds) ->
    timer:sleep(Milliseconds),
    nil.

reason(Reason) ->
    unicode:characters_to_binary(io_lib:format("~p", [Reason])).
