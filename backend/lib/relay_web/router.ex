defmodule RelayWeb.Router do
  use RelayWeb, :router
  pipeline :api do plug :accepts, ["json"] end
  pipeline :authenticated do plug RelayWeb.AuthPipeline end
  scope "/api", RelayWeb do
    pipe_through :api
    post "/auth/register", AuthController, :register
    post "/auth/login", AuthController, :login
    scope "" do
      pipe_through :authenticated
      get "/auth/me", AuthController, :me
      get "/friends", FriendController, :index
      get "/friend-requests", FriendController, :requests
      post "/friend-requests", FriendController, :create
      patch "/friend-requests/:id", FriendController, :update
      get "/conversations", ConversationController, :index
      post "/conversations/direct", ConversationController, :direct
      post "/conversations/group", ConversationController, :group
      get "/conversations/:conversation_id/messages", MessageController, :index
      post "/conversations/:conversation_id/messages", MessageController, :create
      delete "/conversations/:conversation_id/messages/:id", MessageController, :delete
      post "/conversations/:conversation_id/members/:user_id/kick", ModerationController, :kick
      post "/conversations/:conversation_id/members/:user_id/ban", ModerationController, :ban
      get "/conversations/:conversation_id/calls", CallController, :index
      post "/conversations/:conversation_id/calls", CallController, :create
      patch "/calls/:id/end", CallController, :end_call
      get "/notifications", NotificationController, :index
      patch "/notifications/:id/read", NotificationController, :read
    end
  end
  get "/health", RelayWeb.HealthController, :index
end
