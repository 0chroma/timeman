defmodule TimemanWeb.EntryController do
  use TimemanWeb, :controller

  alias Timeman.WorkLog
  alias Timeman.WorkLog.Entry

  action_fallback TimemanWeb.FallbackController

  def index(conn, _params) do
    entries = WorkLog.list_entries()
    render(conn, "index.json", entries: entries)
  end

  def create(conn, %{"entry" => entry_params}) do
    with {:ok, %Entry{} = entry} <- WorkLog.create_entry(entry_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.entry_path(conn, :show, entry))
      |> render("show.json", entry: entry)
    end
  end

  def show(conn, %{"id" => id}) do
    entry = WorkLog.get_entry!(id)
    render(conn, "show.json", entry: entry)
  end

  def update(conn, %{"id" => id, "entry" => entry_params}) do
    entry = WorkLog.get_entry!(id)

    with {:ok, %Entry{} = entry} <- WorkLog.update_entry(entry, entry_params) do
      render(conn, "show.json", entry: entry)
    end
  end

  def delete(conn, %{"id" => id}) do
    entry = WorkLog.get_entry!(id)

    with {:ok, %Entry{}} <- WorkLog.delete_entry(entry) do
      send_resp(conn, :no_content, "")
    end
  end
end
