defmodule Timeman.Repo do
  use Ecto.Repo,
    otp_app: :timeman,
    adapter: Ecto.Adapters.Postgres
end
