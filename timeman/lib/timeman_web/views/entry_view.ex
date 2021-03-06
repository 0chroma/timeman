defmodule TimemanWeb.EntryView do
  use TimemanWeb, :view
  alias TimemanWeb.EntryView
  alias TimemanWeb.UserView

  def render("index.json", %{entries: entries}) do
    render_many(entries, EntryView, "entry.json")
  end

  def render("show.json", %{entry: entry}) do
    render_one(entry, EntryView, "entry.json")
  end

  def render("entry.json", %{entry: entry}) do
    %{id: entry.id,
      date: entry.date,
      hours: entry.hours,
      notes: entry.notes,
      user: UserView.render("user.json", %{user: entry.user})
    }
  end
end
