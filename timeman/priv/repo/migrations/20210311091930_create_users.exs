defmodule Timeman.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string
      add :encrypted_password, :string
      add :role, :string
      add :preferred_hours, :integer

      timestamps()
    end

    create unique_index(:users, [:username])
  end
end
