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

    File.open!(ref_path, [:write, :binary])  |> IO.binwrite(reference)
    File.open!(comp_path, [:write, :binary]) |> IO.binwrite(comparison)

    # compare -metric AE ref.png comp.png d.png
    {{metrics, _}, _time} = measure fn  ->
      System.cmd("compare",
      ["-metric", @compare_metric_type, "-fuzz", fuzz, ref_path, comp_path, diff_path], stderr_to_stdout: true)
     end

    # Leeloo.Instrumenter.instrument_image_compare(time, @compare_metric_type)

    # uncomment next, if interested, for debugging purposes?!
    # Logger.info("#{inspect metrics}: #{diff_path}; time: #{time}")
    Counter.inc(:images, 2)
    Prometheus.Push.push(%{})

    cond do
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
          Prometheus.Push.push(%{})
          Temp.cleanup
          {:error, :no_match, pixels_diff, "data:image/png;base64," <> base64data}
        end

      true ->
        Counter.inc(:matching_images)
        Prometheus.Push.push(%{})
        Temp.cleanup
        {:ok, :match}
    end
  end

  def compare(_, _, _), do: {:error, :invalid_input}

  # measure a function execution and returns its result(s) and the execution time in seconds
  defp measure(func) do
    {time, results} = func |> :timer.tc # microseconds ( μs)
    {results, time/1_000_000}
  end

  # defp pretty_time(ms) do
  #   Float.floor(ms/1_000_000, 1) |> Kernel.to_string
  # end
end
