import Config
if config_env() == :prod do
  database_url = System.fetch_env!("DATABASE_URL")
  secret_key_base = System.fetch_env!("SECRET_KEY_BASE")
  config :relay, Relay.Repo, url: database_url, pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"), socket_options: if(System.get_env("ECTO_IPV6"), do: [:inet6], else: [])
  config :relay, Relay.Guardian, secret_key: System.fetch_env!("GUARDIAN_SECRET")
  config :relay, RelayWeb.Endpoint, server: true, url: [host: System.get_env("PHX_HOST") || "localhost", port: 443, scheme: "https"], http: [ip: {0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT") || "4000")], secret_key_base: secret_key_base
  config :relay, :cors_origins, System.get_env("CORS_ORIGINS", "https://#{System.get_env("PHX_HOST") || "localhost"}") |> String.split(",", trim: true)

  if query = System.get_env("DNS_CLUSTER_QUERY") do
    if query != "", do: config(:libcluster, topologies: [dns: [strategy: Cluster.Strategy.DNSPoll, config: [query: query]]])
  end
end
