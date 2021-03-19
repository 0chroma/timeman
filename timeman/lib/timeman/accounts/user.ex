defmodule Timeman.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :username, :string
    field :encrypted_password, :string, redact: true
    field :password, :string, virtual: true
    field :role, Ecto.Enum, values: [:user, :manager, :admin], default: :user
    field :preferred_hours, :integer

    timestamps()

    has_many :entries, Timeman.WorkLog.Entry
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :password, :role, :preferred_hours])
    |> validate_required([:username])
    |> validate_format(:username, ~r/^[A-Za-z0-9._-]+$/)
    |> validate_length(:password, min: 8)
    |> unique_constraint(:username)
    |> validate_number(:preferred_hours, less_than: 24, greater_than: 0)
    |> put_hashed_password
  end

  defp put_hashed_password(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}}
        ->
          put_change(changeset, :encrypted_password, Bcrypt.hash_pwd_salt(password))
      _ ->
          changeset
    end
  end
end
