defmodule Relay.MixProject do
  use Mix.Project

  def project do
    [app: :relay, version: "0.1.0", elixir: "~> 1.14", elixirc_paths: elixirc_paths(Mix.env()), start_permanent: Mix.env() == :prod, deps: deps()]
  end

  def application do
    [mod: {Relay.Application, []}, extra_applications: [:logger, :runtime_tools]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.7.14"}, {:phoenix_ecto, "~> 4.5"}, {:ecto_sql, "~> 3.11"},
      {:postgrex, ">= 0.0.0"}, {:phoenix_html, "~> 4.1"}, {:phoenix_live_view, "~> 0.20.2"},
      {:phoenix_pubsub, "~> 2.1"}, {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:bandit, "~> 1.5"}, {:jason, "~> 1.4"},
      {:guardian, "~> 2.3"}, {:cors_plug, "~> 3.0"}, {:bcrypt_elixir, "~> 3.1"},
      {:plug, "~> 1.16"}, {:mime, "~> 2.0"},
      {:telemetry_metrics, "~> 1.0"}, {:telemetry_poller, "~> 1.0"},
      {:libcluster, "~> 3.3"}
    ]
  end
end
