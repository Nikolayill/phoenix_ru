defmodule Discuss.Repo.Migrations.AddTopics do
  use Ecto.Migration

  def change do
    create table(:topics) do  # CREATE TABLE topics
      add :title, :string     # ADD title VARCHAR(255)
    end
  end
end
