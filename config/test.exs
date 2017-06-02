use Mix.Config

config :maru, Leeloo.Api,
  http: [port: 8088]

config :mix_test_watch,
  clear: true,
  tasks: ["espec --cover"]
