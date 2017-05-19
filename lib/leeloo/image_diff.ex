defmodule Leeloo.ImageDiff do
  @moduledoc """
  Matcher contains the support for using Imagemagick for comparing two PNG images
  """

  @doc """
  compare two images: reference and comparison, images transmitted as
  Base64 encoded PNG strings

  """
  def compare(reference, comparison) when is_binary(reference) and is_binary(comparison) do
    Temp.track!
    dir_path = Temp.mkdir!("leeloo")

    ref_path = Temp.open! "ref.png", &IO.binwrite(&1, from_data_url(reference))
    comp_path = Temp.open! "comp.png", &IO.binwrite(&1, from_data_url(comparison))
    diff_path = Path.join(dir_path, "diff.png")

    # compare -metric AE ref.png comp.png d.png
    {metrics, _} = System.cmd("compare",
      ["-metric", "AE", ref_path, comp_path, diff_path], stderr_to_stdout: true)

    # uncomment next, if interested, for debugging purposes?!
    # IO.puts("#{inspect metrics}: #{diff_path}")
    cond do
      (pixels_diff = String.to_integer(metrics)) > 0 ->
        with {:ok, imageData} <- File.read(diff_path) do
          base64data = Base.encode64(imageData)
          Temp.cleanup
          {:error, :no_match, pixels_diff, "data:image/png;base64," <> base64data}
        end
      true ->
        Temp.cleanup
        {:ok, :match}
    end
  end

  def compare(_, _), do: {:error, :invalid_input}

  #extract the image corpus from an encoded data_url parameter
  defp from_data_url(data) do
    cond do
      String.starts_with?(data, "data:image/png;base64,") ->
        data |> String.split(",") |> List.last |> Base.decode64!
      true -> data
    end
  end
end
