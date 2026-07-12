import Config
config :relay, Relay.Repo, username: "postgres", password: "postgres", hostname: "localhost", database: "relay_dev", show_sensitive_data_on_connection_error: true, pool_size: 10
config :relay, RelayWeb.Endpoint, http: [ip: {127, 0, 0, 1}, port: 4000], check_origin: false, code_reloader: true, debug_errors: true, secret_key_base: "development-secret-key-base-development-secret-key-base-0123456789"
