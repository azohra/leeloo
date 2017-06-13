use Mix.Config

config :maru, Leeloo.Api,
  http: [ip: {0,0,0,0}, port: 4000],
  token: "" # Add your own token here

config :mix_test_watch,
  clear: true,
  tasks: ["espec"]
