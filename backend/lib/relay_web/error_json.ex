defmodule RelayWeb.ErrorJSON do
  def render(template, assigns) do
    status = Phoenix.Controller.status_message_from_template(template)
    %{error: %{code: template |> String.replace_suffix(".json", ""), message: assigns[:reason] || status}}
  end
end
