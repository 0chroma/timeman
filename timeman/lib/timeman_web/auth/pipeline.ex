defmodule TimemanWeb.Auth.Pipeline do
  use Guardian.Plug.Pipeline, otp_app: :timeman,
    module: TimemanWeb.Auth.Guardian,
    error_handler: TimemanWeb.Auth.ErrorHandler

  plug Guardian.Plug.VerifyHeader
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
