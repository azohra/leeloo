defmodule Leeloo.ApiSpec do
  use ESpec
  use Maru.Test, for: Leeloo.Api

  @leeloo "Leeloo"

  describe "API" do
    context "Basic API function" do
      it "respond with :ok to a simple get"  do
        expect(get("/api") |> text_response).to eq ":ok"
      end

      it "echoes back, on valid params" do
        r = build_conn()
          |> put_body_or_params(%{text: @leeloo})
          |> post("/api/echo")
          |> json_response
        expect(r).to eq %{"echo" => @leeloo}
      end

      it "echoes back `Sup?!` for invalid attributes" do
        r = build_conn()
          |> post("/api/echo")
          |> json_response
        expect(r).to eq %{"echo" => "Sup?!"}
      end
    end

    context "different images or no images at all" do
      let :diff_images do
        %{images: %{
            reference: shared.image_reference,
            comparison: shared.image_comparison}
        }
      end

      let :no_images, do: %{images: %{ reference: nil, comparison: nil}}
      let :similar_images, do: %{images: %{ reference: shared.image_reference, comparison: shared.image_reference}}

      it "ignores the requests with invalid parameters" do
        r = build_conn()
          |> put_body_or_params(no_images())
          |> post("/api/compare/png_strings")
          |> json_response
        expect(r).to eq %{"error" => "invalid_input"}
      end

      it "finds no difference between two similar images" do
        r = build_conn()
          |> put_body_or_params(similar_images())
          |> post("/api/compare/png_strings")
          |> json_response

        expect(r).to eq %{"ok" => "match"}
      end

      it "returns the metric difference between two different images and the encoded visual difference" do
        r = build_conn()
          |> put_body_or_params(diff_images())
          |> post("/api/compare/png_strings")
          |> json_response

        expect(r["diff_metric"]).to be 526
        expect(r["diff_visual"]).to start_with("data:image/png;base64,")
        expect(r["error"]).to eq("no_match")
      end
    end
  end
end
