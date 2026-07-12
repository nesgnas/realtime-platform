defmodule RelayWeb.MessageController do
  use RelayWeb, :controller
  alias Relay.{Chat, Guardian}; alias RelayWeb.Serializer
  def index(conn, %{"conversation_id" => cid} = p) do with {:ok, rows} <- Chat.list_messages(cid, uid(conn), p["before"]), do: json(conn, %{data: Enum.map(rows, &Serializer.message/1)}) end
  def create(conn, %{"conversation_id" => cid} = params) do
    with true <- Chat.member?(cid, uid(conn)),
         attrs <- attachment_attrs(Map.take(params, ["body"]), params["file"]),
         {:ok, row} <- Chat.create_message(cid, uid(conn), attrs) do
      conn |> put_status(:created) |> json(%{data: Serializer.message(row)})
    else
      false -> {:error, :forbidden}
      error -> error
    end
  end
  def delete(conn, %{"conversation_id" => cid, "id" => id}) do with {:ok, row} <- Chat.delete_message(cid, uid(conn), id), do: json(conn, %{data: Serializer.message(row)}) end
  defp store(file) do
    ext = Path.extname(file.filename); name = Ecto.UUID.generate() <> ext; dir = Application.app_dir(:relay, "uploads"); File.mkdir_p!(dir); File.cp!(file.path, Path.join(dir, name))
    %{"attachment_path" => name, "attachment_name" => Path.basename(file.filename), "attachment_type" => file.content_type, "attachment_size" => File.stat!(file.path).size}
  end
  defp attachment_attrs(attrs, %Plug.Upload{} = file), do: Map.merge(attrs, store(file))
  defp attachment_attrs(attrs, _), do: attrs
  defp uid(conn), do: Guardian.Plug.current_resource(conn).id
end
