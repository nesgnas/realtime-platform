defmodule RelayWeb.AuthController do
  use RelayWeb, :controller
  alias Relay.{Accounts, Guardian}
  alias RelayWeb.Serializer
  def register(conn, params) do with {:ok, user} <- Accounts.register_user(params), {:ok, token, _} <- Guardian.encode_and_sign(user), do: conn |> put_status(:created) |> json(%{data: %{user: Serializer.user(user), token: token}}) end
  def login(conn, params) do with {:ok, user} <- Accounts.authenticate(params["email"], params["password"]), {:ok, token, _} <- Guardian.encode_and_sign(user), do: json(conn, %{data: %{user: Serializer.user(user), token: token}}) end
  def me(conn, _), do: json(conn, %{data: Serializer.user(Guardian.Plug.current_resource(conn))})
end
