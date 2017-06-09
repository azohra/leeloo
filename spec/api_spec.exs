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
            reference: shared.image_string_reference,
            comparison: shared.image_string_comparison},
            fuzz: "0%"
        }
      end

      let :no_images, do: %{images: %{ reference: nil, comparison: nil }}
      let :similar_images do
        %{images:
          %{ reference: shared.image_string_reference, comparison: shared.image_string_reference}
        }
      end

      let :similar_png_images do
        %{images:
          %{
            reference:
              %Plug.Upload{
                content_type: "application/octet-stream",
                filename: "p1.png",
                path: shared.image_png_reference_path},
            comparison:
            %Plug.Upload{
              content_type: "application/octet-stream",
              filename: "p1.png",
              path: shared.image_png_reference_path}
          }
        }
      end

      let :different_png_images do
        %{images:
          %{
            reference:
              %Plug.Upload{
                filename: "p1.png",
                path: shared.image_png_reference_path},
            comparison:
            %Plug.Upload{
              filename: "p1_2.png",
              path: shared.image_png_comparison_path}
          }
        }
      end

      it "ignores the requests with invalid parameters" do
        r = build_conn()
          |> put_body_or_params(no_images())
          |> post("/api/compare/png_strings")
          |> json_response
        expect(r).to have_value("invalid_input")
        expect(r).to have_key("transaction")
      end

      it "finds no difference between two similar PNG images" do
        r = build_conn()
          |> put_body_or_params(similar_png_images())
          |> post("/api/compare/pngs")
          |> json_response

        # assert response.status == 201
        expect(r).to have_value("match")
        expect(r).to have_key("transaction")
      end

      it "finds no difference between two similar Base64 encoded images" do
        r = build_conn()
          |> put_body_or_params(similar_images())
          |> post("/api/compare/png_strings")
          |> json_response

        expect(r).to have_value("match")
        expect(r).to have_key("transaction")
      end

      it "returns the metric difference between two different images and the encoded visual difference" do
        r = build_conn()
          |> put_body_or_params(diff_images())
          |> post("/api/compare/png_strings")
          |> json_response

        expect(r["diff_metric"]).to be 526
        expect(r["diff_visual"]).to start_with("data:image/png;base64,")
        expect(r["error"]).to eq("no_match")
        expect(r).to have_key("transaction")
      end
    end
  end

  # defp my_json_response(conn) do
  #   conn.resp_body |> IO.inspect |> Poison.decode!
  # end
end
