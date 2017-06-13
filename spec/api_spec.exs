defmodule Leeloo.ApiSpec do
  use ESpec
  use Maru.Test, for: Leeloo.Api

  # @leeloo "Leeloo"

  describe "API" do
    context "Basic API function" do
      it "respond with :ok to a simple get"  do
        expect(get("/api") |> text_response).to eq ":ok"
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

      it "finds no difference between two similar PNG images" do
        r = build_conn()
          |> put_body_or_params(similar_png_images())
          |> post("/api/compare/pngs")
          |> json_response

        # assert response.status == 201
        expect(r).to have_value("match")
        expect(r).to have_key("transaction")
      end
    end
  end

  # defp my_json_response(conn) do
  #   conn.resp_body |> IO.inspect |> Poison.decode!
  # end
end
