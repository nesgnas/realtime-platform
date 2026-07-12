defmodule RelayWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics
  def start_link(arg), do: Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  @impl true
  def init(_), do: Supervisor.init([{Telemetry.Poller, measurements: periodic_measurements(), period: 10_000}], strategy: :one_for_one)
  def metrics, do: [counter("phoenix.endpoint.stop.duration"), counter("relay.repo.query.total_time")]
  defp periodic_measurements, do: []
end
