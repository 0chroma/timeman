defmodule TimemanWeb.EntryController do
  use TimemanWeb, :controller

  alias Timeman.WorkLog
  alias Timeman.WorkLog.Entry

  action_fallback TimemanWeb.FallbackController

  def index(conn, params) do
    current_user = Guardian.Plug.current_resource(conn)

    with :ok <- Bodyguard.permit(Timeman.WorkLog, :list_entry, current_user) do
      entries = case params do
        %{"start_date" => startD, "end_date" => endD} ->
          with {:ok, start_date} = Date.from_iso8601(startD),
               {:ok, end_date} = Date.from_iso8601(endD)
          do
            WorkLog.list_entries_for_user(current_user, start_date, end_date)
          end
        _ ->
          WorkLog.list_entries_for_user(current_user)
      end
      render(conn, "index.json", entries: entries)
    end
  end

  def create(conn, %{"entry" => entry_params}) do
    current_user = Guardian.Plug.current_resource(conn)
    with :ok <- Bodyguard.permit(Timeman.WorkLog, :create_entry, current_user, entry_params),
         {:ok, %Entry{} = entry} <- WorkLog.create_entry(entry_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.entry_path(conn, :show, entry))
      |> render("show.json", entry: entry)
    end
  end

  def show(conn, %{"id" => id}) do
    current_user = Guardian.Plug.current_resource(conn)
    entry = WorkLog.get_entry!(id)
    with :ok <- Bodyguard.permit(Timeman.WorkLog, :create_entry, current_user, entry) do
      render(conn, "show.json", entry: entry)
    end
  end

  def update(conn, %{"id" => id, "entry" => entry_params}) do
    current_user = Guardian.Plug.current_resource(conn)
    entry = WorkLog.get_entry!(id)

    with :ok <- Bodyguard.permit(Timeman.WorkLog, :update_entry, current_user, entry),
         {:ok, %Entry{} = entry} <- WorkLog.update_entry(entry, entry_params) do
      render(conn, "show.json", entry: entry)
    end
  end

  def delete(conn, %{"id" => id}) do
    current_user = Guardian.Plug.current_resource(conn)
    entry = WorkLog.get_entry!(id)

    with :ok <- Bodyguard.permit(Timeman.WorkLog, :delete_entry, current_user, entry),
         {:ok, %Entry{}} <- WorkLog.delete_entry(entry) do
      send_resp(conn, :no_content, "")
    end
  end
end
