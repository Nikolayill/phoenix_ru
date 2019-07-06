defmodule Discuss.AuthController do
  use Discuss.Web, :controller
  plug Ueberauth

  def callback(conn, params) do
    IO.puts("callback conn")
    IO.inspect(conn.assigns)
    IO.puts("callback params")
    IO.inspect(params)
    IO.puts("callback end")
  end
end
