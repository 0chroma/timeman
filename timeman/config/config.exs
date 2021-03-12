# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :timeman,
  ecto_repos: [Timeman.Repo]

# Configures the endpoint
config :timeman, TimemanWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "g2uzA78RmQfverAX6ObyBxYIHwBcr7ljwitCKosl5VG1/tpWFUbI1ams7RnUiUBV",
  render_errors: [view: TimemanWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Timeman.PubSub,
  live_view: [signing_salt: "Y9+0MyR5"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :timeman, BusiApiWeb.Auth.Guardian,
  issuer: "timeman",
  secret_key: "z7cQIaiXllsHXi2UWICOJvBePoPwmDB3ieko09ehtm6BFhCAXuwSNv5J9nJAMPKR"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
