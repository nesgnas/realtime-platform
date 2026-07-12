defmodule RelayWeb.AuthPipeline do
  use Guardian.Plug.Pipeline, otp_app: :relay, module: Relay.Guardian, error_handler: RelayWeb.AuthErrorHandler
  plug Guardian.Plug.VerifyHeader, realm: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
