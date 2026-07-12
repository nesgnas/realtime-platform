defmodule RelayWeb.FallbackController do
  use RelayWeb, :controller
  def call(conn, {:error, %Ecto.Changeset{} = changeset}), do: conn |> put_status(:unprocessable_entity) |> json(%{error: %{code: "validation_failed", message: "validation failed", details: Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} -> Enum.reduce(opts, msg, fn {k, v}, s -> String.replace(s, "%{#{k}}", to_string(v)) end) end)}})
  def call(conn, {:error, :not_found}), do: error(conn, :not_found, "not_found", "resource not found")
  def call(conn, {:error, :forbidden}), do: error(conn, :forbidden, "forbidden", "not permitted")
  def call(conn, {:error, :invalid_credentials}), do: error(conn, :unauthorized, "invalid_credentials", "invalid email or password")
  def call(conn, {:error, reason}), do: error(conn, :unprocessable_entity, to_string(reason), "request could not be completed")
  defp error(conn, status, code, message), do: conn |> put_status(status) |> json(%{error: %{code: code, message: message}})
end
