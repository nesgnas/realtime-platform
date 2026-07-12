defmodule RelayWeb.HealthController do
  use RelayWeb, :controller

  def index(conn, _params), do: json(conn, %{status: "ok"})
end
