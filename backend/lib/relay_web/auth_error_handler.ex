defmodule RelayWeb.AuthErrorHandler do
  import Plug.Conn
  def auth_error(conn, {type, _}, _opts), do: conn |> put_status(:unauthorized) |> Phoenix.Controller.json(%{error: %{code: type, message: "authentication required"}}) |> halt()
end
