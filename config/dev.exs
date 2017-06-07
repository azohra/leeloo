use Mix.Config

config :maru, Leeloo.Api,
  http: [ip: {0,0,0,0}, port: 4000]

config :mix_test_watch,
  clear: true,
  tasks: ["espec"]

config :prometheus, Leeloo.PipelineInstrumenter,
  labels: [:status_class, :method, :host, :scheme, :request_path],
  duration_buckets: [10, 100, 1_000, 10_000, 100_000,
                     300_000, 500_000, 750_000, 1_000_000,
                     1_500_000, 2_000_000, 3_000_000],
  registry: :default,
  duration_unit: :microseconds
