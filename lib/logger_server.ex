defmodule LoggerServer do
  @moduledoc """
  Server for tracking messages.
  """
  use GenServer

  require Logger

  @severities ~w(high medium low)a
  @interval_seconds 10

  # Client

  def start_link(_) do
    # use a counter to set id of incoming message
    state = %{counter: 0, high_severity_logs: 0, logs: %{}}
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
    @interval_seconds
    |> :timer.seconds()
    |> :timer.send_interval(__MODULE__, :report_logs)

    {:ok, initial_state}
  end

  @impl true
  def handle_call({:log, severity, message}, _from, %{counter: counter} = state) do
    id = counter + 1

    new_state =
      state
      |> put_in([:logs, id], %{severity: severity, message: message})
      |> Map.put(:counter, id)
      |> maybe_increment_high_severity_logs(severity)

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

  @impl true
  def handle_info(:report_logs, state) do
    %{high_severity_logs: log_count} = state

    Logger.info(
      "There have been #{log_count} high severity messages in the last #{@interval_seconds} seconds."
    )

    new_state = Map.put(state, :high_severity_logs, 0)
    {:noreply, new_state}
  end

  defp maybe_increment_high_severity_logs(state, :high) do
    Map.update!(state, :high_severity_logs, &(&1 + 1))
  end

  defp maybe_increment_high_severity_logs(state, _), do: state
end
