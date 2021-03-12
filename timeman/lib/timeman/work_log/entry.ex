defmodule Timeman.WorkLog.Entry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "entries" do
    field :date, :date
    field :hours, :integer
    field :notes, :string
    belongs_to :user, Accounts.User, foreign_key: :user_id, references: :id, define_field: false

    timestamps()
  end

  @doc false
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:date, :hours, :notes])
    |> validate_required([:date, :hours, :notes])
  end
end
