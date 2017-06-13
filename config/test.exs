use Mix.Config

config :maru, Leeloo.Api,
  http: [port: 8088],
  token: "" # Add your own token here

config :mix_test_watch,
  clear: true,
  tasks: ["espec --cover"]


