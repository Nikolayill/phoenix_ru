defmodule Discuss.UserSocket do
  use Phoenix.Socket

  # channel "room:*", Discuss.RoomChannel
  channel "comments:*", Discuss.CommentsChannel

  transport :websocket, Phoenix.Transports.WebSocket


  def connect(%{"token" => token}, socket) do
    IO.puts(token)
    {:ok, socket}
  end


  def id(_socket), do: nil
end
