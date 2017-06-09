defmodule Leeloo.ImageDiff do
  require Logger
  use Prometheus.Metric

  @compare_metric_type "AE" #todo: Make me a configurable request param!

  @moduledoc """
  Matcher contains the support for using Imagemagick for comparing two PNG images
  """

  @doc """
  compare two images: reference and comparison, images transmitted as
  Base64 encoded PNG strings

  """
  def compare(reference, comparison, fuzz \\ "0%")
  def compare(reference, comparison, fuzz) when is_binary(reference) and is_binary(comparison) do
    Temp.track!
    dir_path = Temp.mkdir!("leeloo")

    ref_path = Path.join(dir_path, "ref.png")
    comp_path = Path.join(dir_path, "comp.png")
    diff_path = Path.join(dir_path, "diff.png")

    File.open!(ref_path, [:write, :binary])  |> IO.binwrite(from_data_url(reference))
    File.open!(comp_path, [:write, :binary]) |> IO.binwrite(from_data_url(comparison))

    # compare -metric AE ref.png comp.png d.png
    {{metrics, _}, time} = measure fn  ->
      System.cmd("compare",
      ["-metric", @compare_metric_type, "-fuzz", fuzz, ref_path, comp_path, diff_path], stderr_to_stdout: true)
     end

    # Logger.info time
    Leeloo.Instrumenter.instrument_image_compare(time, @compare_metric_type)
    # Counter.inc([name: "processed_images", labels: [:images], registry: :default])

    # uncomment next, if interested, for debugging purposes?!
    # IO.puts("#{inspect metrics}: #{diff_path}")
    Counter.inc(:images, 2)
    # Prometheus.Push.push(%{job: "images", grouping_key: [{"leeloo", "images"}]})

    r = cond do
      String.starts_with?(metrics, "compare: image widths or heights differ") ->
        Counter.inc(:not_matching_images)
        Prometheus.Push.push(%{})
        # Prometheus.Push.push(%{job: "not_matching_images", grouping_key: [{"leeloo", "images"}]})
        Temp.cleanup
        {:error, :widths_or_heights_differ}

      (pixels_diff = String.to_integer(metrics)) > 0 ->
        with {:ok, imageData} <- File.read(diff_path) do
          base64data = Base.encode64(imageData)
          Counter.inc(:not_matching_images)
          # Prometheus.Push.push(%{job: "not_matching_images", grouping_key: [{"leeloo", "images"}]})
          Temp.cleanup
          {:error, :no_match, pixels_diff, "data:image/png;base64," <> base64data}
        end
      true ->
        Counter.inc(:matching_images)
        # Prometheus.Push.push(%{job: "matching_images", grouping_key: [{"leeloo", "images"}]})
        Temp.cleanup
        {:ok, :match}
    end
    Prometheus.Push.push(%{})
    r
  end

  def compare(_, _, _), do: {:error, :invalid_input}

  #extract the image corpus from an encoded data_url parameter
  defp from_data_url(data) do
    cond do
      String.starts_with?(data, "data:image/png;base64,") ->
        data |> String.split(",") |> List.last |> Base.decode64!
      true ->
        data
    end
  end

  # measure a function execution and returns its result(s) and the execution time in seconds
  defp measure(func) do
    {time, results} = func |> :timer.tc # microseconds ( μs)
    {results, time/1_000_000}
  end

  # defp pretty_time(ms) do
  #   Float.floor(ms/1_000_000, 1) |> Kernel.to_string
  # end
end
