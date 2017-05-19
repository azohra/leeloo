use Mix.Config

config :maru, Leeloo.Api,
  http: [port: 8080]

config :mix_test_watch,
  clear: true,
  tasks: ["espec"]
