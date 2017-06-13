use Mix.Config

# config :maru, Leeloo.Api,
#   http: [ip: {0,0,0,0}, port: 4000]

config :maru, Leeloo.Api,
  server: true,
  # use {:system, var} if library supports it
  http: [ip: {0,0,0,0}, port: {:system, "PORT"}],
  # use ${VAR} syntax to replace config on startup
  url: [ host: "${APP_DOMAIN}" ],
  token: "" # Add your own token here

