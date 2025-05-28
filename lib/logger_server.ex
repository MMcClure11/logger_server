defmodule LoggerServer do
  @moduledoc """
  Server for tracking messages.
  """
  use GenServer

  @severities ~w(high medium low)a

  # Client

  def start_link(_) do
    # use a counter to set id of incoming message
    state = %{counter: 0, logs: %{}}
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def log(severity, message) when severity in @severities do
    GenServer.call(__MODULE__, {:log, severity, message})
  end

  def log(_, _), do: {:error, "Severity must be one of #{inspect(@severities)}."}

  def get_log_by_id(id) do
    GenServer.call(__MODULE__, {:get_log, id})
  end

  # Server Callbacks

  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl true
  def handle_call({:log, severity, message}, _from, %{counter: counter} = state) do
    id = counter + 1

    new_state =
      state
      |> put_in([:logs, id], %{severity: severity, message: message})
      |> Map.put(:counter, id)

    # return the message with its id to the client so the user knows its
    # assigned id
    response = %{id: id, message: message}

    {:reply, response, new_state}
  end

  @impl true
  def handle_call({:get_log, id}, _from, %{logs: logs} = state) do
    log = Map.get(logs, id)
    {:reply, log, state}
  end
end
