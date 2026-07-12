import Config

config :relay,
  ecto_repos: [Relay.Repo],
  generators: [binary_id: true, timestamp_type: :utc_datetime_usec]

config :relay, RelayWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [formats: [json: RelayWeb.ErrorJSON], layout: false],
  pubsub_server: Relay.PubSub,
  live_view: [signing_salt: "relay-live"]

config :relay, Relay.Guardian,
  issuer: "relay",
  secret_key: System.get_env("GUARDIAN_SECRET") || "dev-only-change-me-please-at-least-32-bytes"

config :logger, :console, format: "$time $metadata[$level] $message\n", metadata: [:request_id]
config :phoenix, :json_library, Jason
import_config "#{config_env()}.exs"
