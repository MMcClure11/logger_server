# LoggerServer

**Message Server**

## Task 1
- Implement a public function `log/2` that accepts a message and the severity of that message. Store that message along with its severity for later retrieval.

## Task 2
- Implement a public function `get_log_by_id/1` that accepts the message id and returns the message.

## Task 3
- Implement an interval that at the end of each time period, writes to the console the number of messages that were logged in that time.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `logger_server` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:logger_server, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/logger_server>.

