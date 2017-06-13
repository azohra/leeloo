defmodule Leeloo.ImageDiffSpec do
  use ESpec

  alias Leeloo.ImageDiff

  describe "Compare two images" do
    it "is a match between two similar PNG images " do
      expect(ImageDiff.compare(File.read!(shared.image_png_reference_path),
        File.read!(shared.image_png_reference_path))).to eq({:ok, :match})
    end

    it "is a match between two **different** PNG images when the fuzz factor is 100%" do
      expect(ImageDiff.compare(File.read!(shared.image_png_reference_path),
        File.read!(shared.image_png_comparison_path), "100%")).to eq({:ok, :match})
    end

    it "returns and error when comparing two different PNG images " do
      {:error, :no_match, metrics, _diff} =
        ImageDiff.compare(File.read!(shared.image_png_reference_path),
              File.read!(shared.image_png_comparison_path))
      expect({:error, :no_match, metrics}).to eq({:error, :no_match, 526})
    end

    it "returns :error for invalid image data" do
      expect(ImageDiff.compare(nil,nil)).to eq({:error, :invalid_input})
    end
  end
end
