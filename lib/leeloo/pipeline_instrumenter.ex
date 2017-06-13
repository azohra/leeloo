defmodule Leeloo.PipelineInstrumenter do
  # require Logger

  use Prometheus.PlugPipelineInstrumenter

  def label_value(:request_path, conn) do
    # Logger.info(conn.request_path)
    Regex.replace(~r/(.*)(\/.*\.png)$/, conn.request_path, "\\g{1}")
  end

end
