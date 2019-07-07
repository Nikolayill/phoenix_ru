defmodule Discuss.AuthController do
  use Discuss.Web, :controller
  plug Ueberauth

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, params) do
    IO.puts("callback conn.assigns.auth")
    IO.inspect(auth)
    IO.puts("callback params")
    IO.inspect(params)
    IO.puts("callback end")
  end
end
