defmodule RelayWeb.CORS do
  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    origins = Application.get_env(:relay, :cors_origins, ["http://localhost:3000", "http://localhost:5173"])
    CORSPlug.call(conn, CORSPlug.init(origin: origins, credentials: true))
  end
end
