defmodule Discuss.Repo.Migrations.AddUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string
      add :provider, :string   # провайдер аутентификации
      add :token, :string

      timestamps()
    end
  end
end
