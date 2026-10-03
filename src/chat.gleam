import gleam/int
import gleam/io

/// An opaque TCP socket handled by the Erlang runtime.
pub type Socket

@external(erlang, "chat_ffi", "listen")
fn do_listen(port: Int) -> Result(Socket, String)

@external(erlang, "chat_ffi", "accept")
fn do_accept(listen_socket: Socket) -> Result(Socket, String)

@external(erlang, "chat_ffi", "connect")
fn do_connect(host: String, port: Int) -> Result(Socket, String)

@external(erlang, "chat_ffi", "send_line")
fn send_line(socket: Socket, line: String) -> Nil

@external(erlang, "chat_ffi", "recv_line")
fn recv_line(socket: Socket) -> Result(String, String)

@external(erlang, "chat_ffi", "close")
fn close(socket: Socket) -> Nil

@external(erlang, "chat_ffi", "timestamp")
fn timestamp() -> String

@external(erlang, "chat_ffi", "getenv")
fn getenv(name: String) -> String

@external(erlang, "chat_ffi", "sleep")
fn sleep(milliseconds: Int) -> Nil

pub fn main() -> Nil {
  let role = getenv("CHAT_ROLE")
  let delay_ms = int_from_env("CHAT_DELAY_MS", 0)

  case role {
    "initiator" -> run_initiator(delay_ms)
    _ -> run_responder(delay_ms)
  }
}

fn run_initiator(delay_ms: Int) -> Nil {
  let peer_ip = getenv("CHAT_PEER_IP")
  let peer_port = int_from_env("CHAT_PEER_PORT", 4001)
  let start = int_from_env("CHAT_START", 0)

  io.println(log("initiator: connecting to " <> peer_ip <> ":" <> int.to_string(peer_port)))

  case do_connect(peer_ip, peer_port) {
    Ok(socket) -> {
      io.println(log("initiator: sending start value " <> int.to_string(start)))
      send_line(socket, int.to_string(start))
      loop(socket, delay_ms)
    }
    Error(reason) -> {
      io.println(log("initiator: connect failed: " <> reason))
      Nil
    }
  }
}

fn run_responder(delay_ms: Int) -> Nil {
  let listen_port = int_from_env("CHAT_LISTEN_PORT", 4000)

  io.println(log("responder: listening on 0.0.0.0:" <> int.to_string(listen_port)))

  case do_listen(listen_port) {
    Ok(listen_socket) -> {
      case do_accept(listen_socket) {
        Ok(socket) -> {
          io.println(log("responder: peer connected"))
          loop(socket, delay_ms)
        }
        Error(reason) -> {
          io.println(log("responder: accept failed: " <> reason))
          Nil
        }
      }
    }
    Error(reason) -> {
      io.println(log("responder: listen failed: " <> reason))
      Nil
    }
  }
}

fn loop(socket: Socket, delay_ms: Int) -> Nil {
  case recv_line(socket) {
    Ok(line) ->
      case int.parse(line) {
        Ok(received) -> {
          let next = received + 1
          io.println(
            log(
              "received "
              <> int.to_string(received)
              <> " -> sending "
              <> int.to_string(next),
            ),
          )
          sleep(delay_ms)
          send_line(socket, int.to_string(next))
          loop(socket, delay_ms)
        }
        Error(_) -> {
          io.println(log("ignoring non-integer message: " <> line))
          loop(socket, delay_ms)
        }
      }
    Error(reason) -> {
      io.println(log("connection closed: " <> reason))
      close(socket)
      Nil
    }
  }
}

fn log(message: String) -> String {
  "[" <> timestamp() <> "] " <> message
}

fn int_from_env(name: String, default: Int) -> Int {
  case getenv(name) {
    "" -> default
    value ->
      case int.parse(value) {
        Ok(number) -> number
        Error(_) -> default
      }
  }
}
