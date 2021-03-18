defmodule TimemanWeb.UserView do
  use TimemanWeb, :view
  alias TimemanWeb.UserView

  def render("index.json", %{users: users}) do
    render_many(users, UserView, "user.json")
  end

  def render("show.json", %{user: user}) do
    render_one(user, UserView, "user.json")
  end

  def render("user.json", %{user: user}) do
    %{id: user.id,
      username: user.username,
      role: user.role,
      preferredHours: user.preferred_hours
    }
  end

  def render("user_token.json", %{user: user, token: token}) do
    data = render "user.json", %{user: user}
    Map.put data, :token, token
  end
end
