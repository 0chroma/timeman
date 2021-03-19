defmodule Timeman.WorkLog do
  @behaviour Bodyguard.Policy

  @moduledoc """
  The WorkLog context.
  """

  import Ecto.Query, warn: false
  alias Timeman.Repo

  alias Timeman.WorkLog.Entry

  @doc """
  Returns the list of entries.

  ## Examples

      iex> list_entries()
      [%Entry{}, ...]

  """
  def list_entries do
    Repo.all(Entry)
  end

  def list_entries_for_user(user) do
    Entry
    |> Bodyguard.scope(user)
    |> Repo.all
  end

  @doc """
  Gets a single entry.

  Raises `Ecto.NoResultsError` if the Entry does not exist.

  ## Examples

      iex> get_entry!(123)
      %Entry{}

      iex> get_entry!(456)
      ** (Ecto.NoResultsError)

  """
  def get_entry!(id), do: Repo.get!(Entry, id)

  @doc """
  Creates a entry.

  ## Examples

      iex> create_entry(%{field: value})
      {:ok, %Entry{}}

      iex> create_entry(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_entry(attrs \\ %{}) do
    %Entry{}
    |> Entry.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a entry.

  ## Examples

      iex> update_entry(entry, %{field: new_value})
      {:ok, %Entry{}}

      iex> update_entry(entry, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_entry(%Entry{} = entry, attrs) do
    entry
    |> Entry.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a entry.

  ## Examples

      iex> delete_entry(entry)
      {:ok, %Entry{}}

      iex> delete_entry(entry)
      {:error, %Ecto.Changeset{}}

  """
  def delete_entry(%Entry{} = entry) do
    Repo.delete(entry)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking entry changes.

  ## Examples

      iex> change_entry(entry)
      %Ecto.Changeset{data: %Entry{}}

  """
  def change_entry(%Entry{} = entry, attrs \\ %{}) do
    Entry.changeset(entry, attrs)
  end

  # Admins can CRUD anything
  def authorize(:list_entry, %{role: :admin} = _current_user, _entry), do: :ok
  def authorize(:create_entry, %{role: :admin} = _current_user, _entry), do: :ok
  def authorize(:read_entry, %{role: :admin} = _current_user, _entry), do: :ok
  def authorize(:update_entry, %{role: :admin} = _current_user, _entry), do: :ok
  def authorize(:delete_entry, %{role: :admin} = _current_user, _entry), do: :ok

  # Users can CRUD their own entries
  def authorize(:list_entry, %{id: user_id} = _current_user, _entry), do: :ok # scoped down by query
  def authorize(:create_entry, %{id: user_id} = _current_user, %{user_id: user_id} = _entry), do: :ok
  def authorize(:read_entry, %{id: user_id} = _current_user, %{user_id: user_id} = _entry), do: :ok
  def authorize(:update_entry, %{id: user_id} = _current_user, %{user_id: user_id} = _entry), do: :ok
  def authorize(:delte_entry, %{id: user_id} = _current_user, %{user_id: user_id} = _entry), do: :ok

  # Otherwise, denied
  def authorize(:list_entry, _current_user, _entry), do: :error
  def authorize(:create_entry, _current_user, _user), do: :error
  def authorize(:read_entry, _current_user, _entry), do: :error
  def authorize(:update_entry, _current_user, _entry), do: :error
  def authorize(:delete_entry, _current_user, _entry), do: :error
end
