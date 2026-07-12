defmodule RelayWeb do
  def controller do
    quote do
      use Phoenix.Controller, formats: [:json]
      import Plug.Conn
      alias RelayWeb.Router.Helpers, as: Routes
      action_fallback RelayWeb.FallbackController
    end
  end
  def channel do
    quote do
      use Phoenix.Channel
      alias RelayWeb.Serializer
    end
  end
  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end
  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes, endpoint: RelayWeb.Endpoint, router: RelayWeb.Router, statics: RelayWeb.static_paths()
    end
  end
  defmacro __using__(which) when is_atom(which), do: apply(__MODULE__, which, [])
  def static_paths, do: ~w(uploads)
end
