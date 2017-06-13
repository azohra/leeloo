defmodule Leeloo.Mixfile do
  use Mix.Project

  def project do
    [app: :leeloo,
     version: "0.3.1",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     preferred_cli_env: [
        espec: :test, coveralls: :test, "coveralls.detail": :test,
        "coveralls.post": :test, "coveralls.html": :test],
     test_coverage: [tool: ExCoveralls],
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [ :prometheus, :logger, :maru, :prometheus_ex,
          :prometheus_plugs, :prometheus_push],
     mod: {Leeloo, []}]
  end

  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:maru, "~> 0.11.4"},
      {:espec, "~> 1.4", only: :test},
      {:temp, "~> 0.4.3"},
      {:excoveralls, "~> 0.6.3", only: [:dev, :test]},
      {:mix_test_watch, "~> 0.4.0"},
      {:secure_random, "~> 0.5"},
      {:sizeable, "~> 1.0"},
      {:prometheus_ex, "~> 1.0"},
      {:prometheus_push, "~> 0.0.1"},
      {:decorator, "~> 0.4"},
      {:prometheus_plugs, "~> 1.0"} #,
      # not for OSX:
      # {:prometheus_process_collector, "~> 1.0"}
    ]
  end
end
