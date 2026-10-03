# chat

A two-node Gleam counter ping-pong over TCP. One node starts with `0`, sends
it to the other, the receiver adds `1` and sends it back, and so on forever.
Every increment is printed to stdout with a UTC timestamp.

## How the two machines find each other

Each machine has its own private IP, so **nothing is hard-coded**. The app reads
the addresses from environment variables at startup. You set them on the shell
(or a service manager / `env` file) *before* starting the app.

| Variable           | Meaning                                        | Default | Used by      |
| ------------------ | ---------------------------------------------- | ------- | ------------ |
| `CHAT_ROLE`        | `initiator` or `responder`                     | responder | both       |
| `CHAT_LISTEN_PORT` | local TCP port to listen on                    | `4000`  | responder    |
| `CHAT_PEER_IP`     | the **other** machine's private IP             | none    | initiator    |
| `CHAT_PEER_PORT`   | the **other** machine's listening port         | `4001`  | initiator    |
| `CHAT_START`       | value to start with (only set on initiator)    | `0`     | initiator    |
| `CHAT_DELAY_MS`    | optional pause between exchanges (0 = max speed) | `0`   | both         |

So to tell the app about the IPs you export `CHAT_PEER_IP` on the machine that
starts the exchange, and `CHAT_LISTEN_PORT` on the machine that waits.

## Example with two private IPs

Machine **B** (responder, IP `10.0.0.2`) starts first and listens on port 4000:

```sh
CHAT_ROLE=responder CHAT_LISTEN_PORT=4000 CHAT_DELAY_MS=200 gleam run
```

Machine **A** (initiator, IP `10.0.0.1`) points at B and sends the initial `0`:

```sh
CHAT_ROLE=initiator CHAT_PEER_IP=10.0.0.2 CHAT_PEER_PORT=4000 CHAT_START=0 gleam run
```

Output on each node looks like:

```
[2026-10-03T20:43:17.305Z] initiator: sending start value 0
[2026-10-03T20:43:17.319Z] received 0 -> sending 1     # node B
[2026-10-03T20:43:17.537Z] received 1 -> sending 2     # node A
[2026-10-03T20:43:17.739Z] received 2 -> sending 3     # node B
...
```

Make sure the port is allowed through any firewall between the two machines.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
