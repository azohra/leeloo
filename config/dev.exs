use Mix.Config

config :maru, Leeloo.Api,
  http: [ip: {0,0,0,0}, port: 8080]

config :mix_test_watch,
  clear: true,
  tasks: ["espec"]
