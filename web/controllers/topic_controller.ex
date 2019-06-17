defmodule Discuss.TopicController do
  use Discuss.Web, :controller

  alias Discuss.Topic

  def new(conn, params) do
    changeset = Topic.changeset(%Topic{}, %{})

    render conn, "new.html", changeset: changeset
  end

  def create(conn, %{"topic" => topic} = params) do
    IO.puts("create form data")
    IO.inspect(params)
    IO.inspect(topic)
  end
end
