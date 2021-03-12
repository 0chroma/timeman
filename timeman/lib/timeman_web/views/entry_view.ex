defmodule TimemanWeb.EntryView do
  use TimemanWeb, :view
  alias TimemanWeb.EntryView

  def render("index.json", %{entries: entries}) do
    %{data: render_many(entries, EntryView, "entry.json")}
  end

  def render("show.json", %{entry: entry}) do
    %{data: render_one(entry, EntryView, "entry.json")}
  end

  def render("entry.json", %{entry: entry}) do
    %{id: entry.id,
      date: entry.date,
      hours: entry.hours,
      notes: entry.notes}
  end
end
