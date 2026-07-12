defmodule Relay.Application do
  use Application
  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies, [])
    children = [{Cluster.Supervisor, [topologies, [name: Relay.ClusterSupervisor]]}, Relay.Repo, {Phoenix.PubSub, name: Relay.PubSub}, RelayWeb.Presence, RelayWeb.Endpoint]
    Supervisor.start_link(children, strategy: :one_for_one, name: Relay.Supervisor)
  end
  @impl true
  def config_change(changed, _new, removed), do: RelayWeb.Endpoint.config_change(changed, removed)
end
