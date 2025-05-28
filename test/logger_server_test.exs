defmodule LoggerServerTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog

  setup do
    {:ok, _pid} = LoggerServer.start_link(nil)
    :ok
  end

  describe "start_link/1" do
    test "starts with initial state" do
      state = :sys.get_state(LoggerServer)
      assert state == %{counter: 0, high_severity_logs: 0, logs: %{}}
    end
  end

  describe "log/2" do
    test "logs a message with valid severity" do
      result = LoggerServer.log(:high, "Critical error")

      assert result == %{id: 1, message: "Critical error"}

      state = :sys.get_state(LoggerServer)
      assert state.counter == 1
      assert state.logs[1] == %{severity: :high, message: "Critical error"}
    end

    test "increments counter for multiple logs" do
      LoggerServer.log(:high, "First message")
      result = LoggerServer.log(:medium, "Second message")

      assert result == %{id: 2, message: "Second message"}

      state = :sys.get_state(LoggerServer)
      assert state.counter == 2
      assert map_size(state.logs) == 2
    end

    test "handles all valid severities" do
      high_result = LoggerServer.log(:high, "High priority")
      medium_result = LoggerServer.log(:medium, "Medium priority")
      low_result = LoggerServer.log(:low, "Low priority")

      assert high_result.id == 1
      assert medium_result.id == 2
      assert low_result.id == 3

      state = :sys.get_state(LoggerServer)
      assert state.logs[1].severity == :high
      assert state.logs[2].severity == :medium
      assert state.logs[3].severity == :low
    end

    test "returns error for invalid severity" do
      result = LoggerServer.log("invalid", "Bad message")

      assert result == {:error, "Severity must be one of [:high, :medium, :low]."}

      # State is unchanged
      state = :sys.get_state(LoggerServer)
      assert state == %{counter: 0, high_severity_logs: 0, logs: %{}}
    end
  end

  describe "get_log_by_id/1" do
    test "returns the correct log for the given id" do
      LoggerServer.log(:high, "First message")
      LoggerServer.log(:medium, "Second message")

      assert %{severity: :medium, message: "Second message"} = LoggerServer.get_log_by_id(2)
    end

    test "returns nil when invalid id given" do
      refute LoggerServer.get_log_by_id(1)
    end
  end

  describe "interval reporting" do
    test "reports high severity logs and resets the counter" do
      LoggerServer.log(:high, "Critical failure")
      LoggerServer.log(:high, "Another issue")

      output =
        capture_log(fn ->
          send(LoggerServer, :report_logs)
          Process.sleep(10)
        end)

      assert output =~ "There have been 2 high severity messages"

      output2 =
        capture_log(fn ->
          send(LoggerServer, :report_logs)
          Process.sleep(10)
        end)

      assert output2 =~ "There have been 0 high severity messages"
    end
  end

  describe "state management" do
    test "maintains separate logs with unique IDs" do
      LoggerServer.log(:high, "Message 1")
      LoggerServer.log(:low, "Message 2")
      LoggerServer.log(:medium, "Message 3")

      state = :sys.get_state(LoggerServer)

      assert state.counter == 3
      assert state.logs[1] == %{severity: :high, message: "Message 1"}
      assert state.logs[2] == %{severity: :low, message: "Message 2"}
      assert state.logs[3] == %{severity: :medium, message: "Message 3"}
    end
  end
end
