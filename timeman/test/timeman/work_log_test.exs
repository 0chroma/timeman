defmodule Timeman.WorkLogTest do
  use Timeman.DataCase

  alias Timeman.WorkLog

  describe "entries" do
    alias Timeman.WorkLog.Entry

    @valid_attrs %{date: ~D[2010-04-17], hours: 42, notes: "some notes"}
    @update_attrs %{date: ~D[2011-05-18], hours: 43, notes: "some updated notes"}
    @invalid_attrs %{date: nil, hours: nil, notes: nil}

    def entry_fixture(attrs \\ %{}) do
      {:ok, entry} =
        attrs
        |> Enum.into(@valid_attrs)
        |> WorkLog.create_entry()

      entry
    end

    test "list_entries/0 returns all entries" do
      entry = entry_fixture()
      assert WorkLog.list_entries() == [entry]
    end

    test "get_entry!/1 returns the entry with given id" do
      entry = entry_fixture()
      assert WorkLog.get_entry!(entry.id) == entry
    end

    test "create_entry/1 with valid data creates a entry" do
      assert {:ok, %Entry{} = entry} = WorkLog.create_entry(@valid_attrs)
      assert entry.date == ~D[2010-04-17]
      assert entry.hours == 42
      assert entry.notes == "some notes"
    end

    test "create_entry/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = WorkLog.create_entry(@invalid_attrs)
    end

    test "update_entry/2 with valid data updates the entry" do
      entry = entry_fixture()
      assert {:ok, %Entry{} = entry} = WorkLog.update_entry(entry, @update_attrs)
      assert entry.date == ~D[2011-05-18]
      assert entry.hours == 43
      assert entry.notes == "some updated notes"
    end

    test "update_entry/2 with invalid data returns error changeset" do
      entry = entry_fixture()
      assert {:error, %Ecto.Changeset{}} = WorkLog.update_entry(entry, @invalid_attrs)
      assert entry == WorkLog.get_entry!(entry.id)
    end

    test "delete_entry/1 deletes the entry" do
      entry = entry_fixture()
      assert {:ok, %Entry{}} = WorkLog.delete_entry(entry)
      assert_raise Ecto.NoResultsError, fn -> WorkLog.get_entry!(entry.id) end
    end

    test "change_entry/1 returns a entry changeset" do
      entry = entry_fixture()
      assert %Ecto.Changeset{} = WorkLog.change_entry(entry)
    end
  end
end
