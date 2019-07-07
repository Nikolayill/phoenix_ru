# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :discuss,
  ecto_repos: [Discuss.Repo]

# Configures the endpoint
config :discuss, Discuss.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "alPFMAl2pmsrNkbgYqAy4pUPa9vOmip+dPVHM16bYstRk6aZKrWVHTslZ6zAdSER",
  render_errors: [view: Discuss.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Discuss.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Конфигурация Ueberauth
config :ueberauth, Ueberauth,
  providers: [
    github: { Ueberauth.Strategy.Github, [default_scope: "user,user:email,public_repo"]}
  ]

# Настройки Github OAuth apps
config :ueberauth,  Ueberauth.Strategy.Github.OAuth,
  client_id: "",  # FIXME здесь должен быть Client ID сгенерированный GitHub
  client_secret: ""  # FIXME здесь должен быть Client Secret сгенерированный GitHub

# В этом конфиге продублирована и "перекрыта" секция с данными GitHub,
# что бы они не попадали в публичный доступ.
import_config "ueberauth.secret.exs"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"