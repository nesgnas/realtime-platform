defmodule RelayWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :relay
  socket "/socket", RelayWeb.UserSocket, websocket: true, longpoll: false
  plug Plug.Static, at: "/uploads", from: {:relay, "uploads"}, gzip: false
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end
  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
  plug RelayWeb.CORS
  plug Plug.Parsers, parsers: [:urlencoded, :multipart, :json], pass: ["*/*"], json_decoder: Phoenix.json_library(), length: 25_000_000
  plug Plug.MethodOverride
  plug Plug.Head
  plug RelayWeb.Router
end
