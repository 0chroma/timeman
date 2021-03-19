defmodule TimemanWeb.UserController do
  use TimemanWeb, :controller

  alias Timeman.Accounts
  alias Timeman.Accounts.User
  alias TimemanWeb.Auth.Guardian

  require Logger
   
  action_fallback TimemanWeb.FallbackController

  def index(conn, _params) do
    current_user = Guardian.Plug.current_resource(conn)
    with :ok <- Bodyguard.permit(Timeman.Accounts, :list_user, current_user) do
      users = Accounts.list_users()
      render(conn, "index.json", users: users)
    end
  end

  def create(conn, %{"user" => user_params}) do
    current_user = Guardian.Plug.current_resource(conn)
    Logger.info inspect(current_user)
    with :ok <- Bodyguard.permit(Timeman.Accounts, :create_user, current_user, user_params),
         {:ok, %User{} = user} <- Accounts.create_user(user_params),
         {:ok, token, _claims} <- Guardian.encode_and_sign(user) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.user_path(conn, :show, user))
      |> render("user_token.json", %{user: user, token: token})
    end
  end

  def show(conn, %{"id" => id}) do
    current_user = Guardian.Plug.current_resource(conn)
    user = Accounts.get_user!(id)

    with :ok <- Bodyguard.permit(Timeman.Accounts, :read_user, current_user, user) do
      render(conn, "show.json", user: user)
    end
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    current_user = Guardian.Plug.current_resource(conn)
    user = Accounts.get_user!(id)

    with :ok <- Bodyguard.permit(Timeman.Accounts, :update_user, current_user, user),
         {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
      render(conn, "show.json", user: user)
    end
  end

  def delete(conn, %{"id" => id}) do
    current_user = Guardian.Plug.current_resource(conn)
    user = Accounts.get_user!(id)

    with :ok <- Bodyguard.permit(Timeman.Accounts, :update_user, current_user, user),
         {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end

  def signin(conn, %{"username" => username, "password" => password}) do
    with {:ok, user, token} <- Guardian.authenticate(username, password) do
      conn
      |> put_status(:ok)
      |> render("user_token.json", %{user: user, token: token})
    end
  end
end
