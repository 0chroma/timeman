defmodule Timeman.WorkLog.Entry do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  schema "entries" do
    field :date, :date
    field :hours, :integer, default: 1
    field :notes, :string, default: ""
    belongs_to :user, Timeman.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:date, :hours, :notes, :user_id])
  end

  def scope(query, %Timeman.Accounts.User{id: user_id, role: user_role}, _) do
    case user_role do
      :admin -> query 
      _ -> from ms in query, where: ms.user_id == ^user_id
    end
  end
end
