defmodule Leeloo.Api do
  @moduledoc """
  Documentation for Leeloo.Api.
  """
  use Maru.Router
  use Maru.Type

  require IEx
  require Logger

  alias Leeloo.ImageDiff
  @token Application.get_env(:maru, Leeloo.Api, "")[:token]

  @max_length 52_428_800 # 50MB

  before do
    plug Plug.Logger
    plug Leeloo.MetricsExporter     # makes the /metrics URL happen
    plug Leeloo.PipelineInstrumenter   # measures pipeline exec times

    plug Plug.Static,
      at: "/static", length: @max_length,
      from: Path.join(~w(#{File.cwd!} static))

    plug Plug.Parsers,
      json_decoder: Poison,
      pass: ["*/*"], length: @max_length,
      parsers: [:urlencoded, :json, :multipart]
  end

  namespace :api do
    Mix.Project.app_path <> "/static/"
    get "/", do: text(conn, ":ok")

    desc "compare two uploaded PNG images"
    params do
      requires :images, type: Map do
        requires :reference, type: File, default: nil
        requires :comparison, type: File, default: nil
        requires :fuzz, type: String, default: "0%"
      end
      requires :token, type: String, default: ""
    end
    post "/compare/pngs" do
      if @token != params[:token] do
        conn
        |> put_status(403)
        |> json(%{error: "Authorization error; invalid token"})

        raise("Unauthorized")
      end

      p =
      %{images:
        %{
         comparison: %{name: params[:images][:comparison].filename, content: File.read!(params[:images][:comparison].path)},
         reference: %{name: params[:images][:reference].filename, content: File.read!(params[:images][:reference].path)},
         fuzz: params[:images][:fuzz]
        }
      }
      compare_images(conn, p)
    end
  end


  rescue_from Maru.Exceptions.NotFound, as: e do
    conn
    |> put_status(404)
    |> text("Not Found: /#{e.path_info} ")
  end

  rescue_from :all, as: e do
    conn
    |> put_status(500)
    |> json(%{error: "#{e.message}"})
  end

  defp compare_images(conn, params) do
    {reference, comparison, fuzz} = {params[:images][:reference].content, params[:images][:comparison].content, params[:images][:fuzz]}
    transaction = SecureRandom.urlsafe_base64

    r = case ImageDiff.compare(reference, comparison, fuzz) do
      {:error, :no_match, metrics, difference} ->
        imgdata = difference |> String.split(",") |> List.last |> Base.decode64!
        visual_diff_path = "static/#{transaction}.png"
        {:ok, file} = File.open(visual_diff_path, [:write])
        IO.binwrite(file, imgdata)
        File.close(file)

        %{error: "no_match", diff_metric: metrics, diff_visual: visual_diff_path, transaction: transaction}

      {:ok, :match} ->
        %{ok: "match", transaction: transaction}

      {:error, :widths_or_heights_differ} ->
        %{error: "widths_or_heights_differ", transaction: transaction}

      {:error, :invalid_input} ->
        %{error: "invalid_input", transaction: transaction}

      _ ->
        %{error: "unknown", transaction: transaction}
    end


    conn
    |> log(r, params)
    |> put_status(201)
    |> json(r)
  end

  def log(conn, msg, _params) do
    Logger.info("#{inspect msg}")
    conn
  end
end
