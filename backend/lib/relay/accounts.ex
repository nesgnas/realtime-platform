defmodule Relay.Accounts do
  import Ecto.Query
  alias Relay.{Repo, Accounts.User, Accounts.FriendRequest, Notifications}

  def register_user(attrs), do: %User{} |> User.changeset(attrs) |> Repo.insert()
  def authenticate(email, password) do
    user = Repo.get_by(User, email: String.downcase(email || ""))
    if user && Bcrypt.verify_pass(password || "", user.password_hash), do: {:ok, user}, else: {:error, :invalid_credentials}
  end
  def get_user(id), do: Repo.get(User, id)
  def get_user!(id), do: Repo.get!(User, id)
  def get_user_by_username(username), do: Repo.get_by(User, username: username)

  def list_friends(user_id) do
    Repo.all(
      from u in User,
        join: f in FriendRequest,
        on:
          f.status == :accepted and
            ((f.sender_id == ^user_id and f.recipient_id == u.id) or
               (f.recipient_id == ^user_id and f.sender_id == u.id)),
        order_by: u.username
    )
  end

  def list_requests(user_id), do: Repo.all(from f in FriendRequest, where: f.recipient_id == ^user_id and f.status == :pending, preload: [:sender], order_by: [desc: f.inserted_at])

  def send_friend_request(sender_id, recipient_id) do
    cond do
      sender_id == recipient_id -> {:error, :cannot_friend_self}
      is_nil(Repo.get(User, recipient_id)) -> {:error, :not_found}
      friends?(sender_id, recipient_id) -> {:error, :already_friends}
      request = Repo.get_by(FriendRequest, sender_id: sender_id, recipient_id: recipient_id, status: :pending) ->
        {:ok, request}
      request = Repo.get_by(FriendRequest, sender_id: recipient_id, recipient_id: sender_id, status: :pending) ->
        request |> Ecto.Changeset.change(status: :accepted) |> Repo.update()
      true ->
        result = %FriendRequest{} |> FriendRequest.changeset(%{sender_id: sender_id, recipient_id: recipient_id}) |> Repo.insert()
        case result do
          {:ok, request} -> Notifications.create(recipient_id, "friend_request", %{request_id: request.id, sender_id: sender_id}); result
          other -> other
        end
    end
  end

  def respond_to_request(user_id, id, status) when status in [:accepted, :declined] do
    case Repo.get_by(FriendRequest, id: id, recipient_id: user_id, status: :pending) do
      nil -> {:error, :not_found}
      request -> request |> Ecto.Changeset.change(status: status) |> Repo.update()
    end
  end

  def friends?(a, b) do
    Repo.exists?(from f in FriendRequest, where: f.status == :accepted and ((f.sender_id == ^a and f.recipient_id == ^b) or (f.sender_id == ^b and f.recipient_id == ^a)))
  end
end
