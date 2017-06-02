defmodule Leeloo.Api do
  @moduledoc """
  Documentation for Leeloo.Api.
  """
  use Maru.Router
  require IEx

  alias Leeloo.ImageDiff

  before do
    plug Plug.Logger
    plug Plug.Parsers,
      json_decoder: Poison,
      pass: ["*/*"],
      parsers: [:urlencoded, :json, :multipart]
  end


  namespace :api do
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
    post "/compare/pngs", do: compare_images(conn, params)
  end

  rescue_from :all, as: e do
    conn
    |> put_status(500)
    |> text("ERROR: #{inspect e}")
  end

  defp compare_images(conn, params) do
    r = case ImageDiff.compare(params[:images][:reference], params[:images][:comparison]) do
      {:error, :no_match, metrics, difference} ->
        %{error: "no_match", diff_metric: metrics, diff_visual: difference}
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
