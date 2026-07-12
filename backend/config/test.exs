import Config
config :relay, Relay.Repo, username: "postgres", password: "postgres", hostname: "localhost", database: "relay_test#{System.get_env("MIX_TEST_PARTITION")}", pool: Ecto.Adapters.SQL.Sandbox, pool_size: 10
config :relay, RelayWeb.Endpoint, http: [ip: {127, 0, 0, 1}, port: 4002], secret_key_base: "test-secret-key-base-test-secret-key-base-012345678901234567", server: false
config :logger, level: :warning
config :bcrypt_elixir, :log_rounds, 1
