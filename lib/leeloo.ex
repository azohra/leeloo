defmodule Leeloo do
  use Application
  use Prometheus.Metric

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    # require Prometheus.Registry

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: Leeloo.Worker.start_link(arg1, arg2, arg3)
      # worker(Leeloo.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Leeloo.Supervisor]

    Counter.declare([name: :images, help: "total images"])
    Counter.declare([name: :matching_images, help: "total matching images"])
    Counter.declare([name: :not_matching_images, help: "total not matching images"])

    Leeloo.PipelineInstrumenter.setup()
    # Linux only: Prometheus.Registry.register_collector(:prometheus_process_collector)
    Leeloo.MetricsExporter.setup()

    Supervisor.start_link(children, opts)
  end
end
