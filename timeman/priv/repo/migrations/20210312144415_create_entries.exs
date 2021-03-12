defmodule Timeman.Repo.Migrations.CreateEntries do
  use Ecto.Migration

  def change do
    create table(:entries) do
      add :date, :date
      add :hours, :integer
      add :notes, :text
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:entries, [:user_id])
  end
end
