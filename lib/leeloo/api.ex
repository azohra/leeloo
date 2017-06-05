defmodule Leeloo.Api do
  @moduledoc """
  Documentation for Leeloo.Api.
  """
  use Maru.Router
  require IEx

  alias Leeloo.ImageDiff

  @max_length 52_428_800 # 50MB

  before do
    plug Plug.Logger
    plug Plug.Static,
      at: "/static", length: @max_length,
      from: Path.join(~w(#{File.cwd!} static))

    plug Plug.Parsers,
      json_decoder: Poison,
      pass: ["*/*"], length: @max_length,
      parsers: [:urlencoded, :json, :multipart]
  end


  namespace :api do
    Mix.Project.app_path <> "/static/" |> IO.inspect
    get "/", do: text(conn, ":ok")

    desc "echo back a POSTed value, for test"
    params do
      requires :text, type: String, default: "Sup?!"
    end
    post "/echo" do
      conn
      |> put_status(201)
      |> json(%{echo: params[:text]})
    end

    desc "compare two PNG images specified as Base64 strings"
    params do
      requires :images, type: Map do
        requires :reference, type: String, default: nil
        requires :comparison, type: String, default: nil
      end
    end
    post "/compare/png_strings", do: compare_images(conn, params)

    params do
      requires :images, type: Map do
        requires :reference, type: File, default: nil
        requires :comparison, type: File, default: nil
      end
    end
    post "/compare/pngs" do
      # todo check if the files exist ...
      p =
      %{images:
        %{
         comparison: File.read!(params[:images][:comparison].path),
         reference: File.read!(params[:images][:reference].path)
        }, return_path_to_visual_diff: true
      }
      compare_images(conn, p)
    end
  end

  rescue_from :all, as: e do
    conn
    |> put_status(500)
    |> text("ERROR: #{inspect e}")
  end

  defp compare_images(conn, params) do
    r = case ImageDiff.compare(params[:images][:reference], params[:images][:comparison]) do
      {:error, :no_match, metrics, difference} ->
        if params[:return_path_to_visual_diff] do
          imgdata = difference |> String.split(",") |> List.last |> Base.decode64!
          visual_diff_path = "static/#{SecureRandom.urlsafe_base64}.png"
          {:ok, file} = File.open(visual_diff_path, [:write])
          IO.binwrite(file, imgdata)
          File.close(file)

          %{error: "no_match", diff_metric: metrics, diff_visual: visual_diff_path}
        else
          %{error: "no_match", diff_metric: metrics, diff_visual: difference}
        end

      {:ok, :match} ->
        %{ok: "match"}
      {:error, :invalid_input} -> %{error: "invalid_input"}
      _ -> %{error: "unknown"}
    end

    conn
    |> put_status(201)
    |> json(r)
  end
end
