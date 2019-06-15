defmodule Discuss.TopicController do
  use Discuss.Web, :controller

  def new(conn, params) do
    IO.puts "Discuss.TopicController new"
    IO.puts "\tconn:"
    IO.inspect conn
    IO.puts "\tparams:"
    IO.inspect params
  end
end
