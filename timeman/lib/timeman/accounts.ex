defmodule Timeman.Accounts do
  @behaviour Bodyguard.Policy

  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Timeman.Repo

  alias Timeman.Accounts.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  def user_by_username(username) do
    case Repo.get_by(User, username: username) do
      nil ->
        {:error, :not_found}
      user ->
        {:ok, user}
    end
  end

  # Admins/Managers can CRUD anything
  def authorize(:list_user, %{role: :admin} = _current_user, _user), do: :ok
  def authorize(:create_user, %{role: :admin} = _current_user, _user), do: :ok
  def authorize(:read_user, %{role: :admin} = _current_user, _user), do: :ok
  def authorize(:update_user, %{role: :admin} = _current_user, _user), do: :ok
  def authorize(:delete_user, %{role: :admin} = _current_user, _user), do: :ok

  def authorize(:list_user, %{role: :manager} = _current_user, _), do: :ok
  def authorize(:create_user, %{role: :manager} = _current_user, _user), do: :ok
  def authorize(:read_user, %{role: :manager} = _current_user, _user), do: :ok
  def authorize(:update_user, %{role: :manager} = _current_user, _user), do: :ok
  def authorize(:delete_user, %{role: :manager} = _current_user, _user), do: :ok

  # Users can update/read themselves
  def authorize(:read_user, %{id: user_id} = _current_user, %{id: user_id} = _user), do: :ok
  def authorize(:update_user, %{id: user_id} = _current_user, %{id: user_id} = _user), do: :ok

  # Anyone can register a normal user
  def authorize(:create_user, _current_user, %{"role" => "user"} = _user), do: :ok
  
  # Otherwise, denied
  def authorize(:list_user, _current_user, _), do: :error
  def authorize(:create_user, _current_user, _user), do: :error
  def authorize(:read_user, _current_user, _user), do: :error
  def authorize(:update_user, _current_user, _user), do: :error
  def authorize(:delete_user, _current_user, _user), do: :error
end
