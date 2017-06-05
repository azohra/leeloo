defmodule Leeloo.ImageDiffSpec do
  use ESpec
  alias Leeloo.ImageDiff

  describe "Compare two images" do
    it "returns an error for invalid image data" do
      # due to the how imagemagick handles comparisons we will not be able to obtain a
      # stable base64 string out of the resulting images and that would break this test
      {:error, :no_match, metrics, difference} = ImageDiff.compare(shared.image_string_reference, shared.image_string_comparison)
      expect(difference).to start_with("data:image/png;base64,")
      expect({:error, :no_match, metrics}).to eq({:error, :no_match, 526})
    end

    it "is a match between two similar base64 encoded images " do
      expect(ImageDiff.compare(shared.image_string_reference, shared.image_string_reference)).to eq({:ok, :match})
    end

    it "is a match between two similar PNG images " do
      expect(ImageDiff.compare(File.read!(shared.image_png_reference_path),
        File.read!(shared.image_png_reference_path))).to eq({:ok, :match})
    end

    it "returns and error when comparing two different PNG images " do
      {:error, :no_match, metrics, _difference} =
        ImageDiff.compare(File.read!(shared.image_png_reference_path),
              File.read!(shared.image_png_comparison_path))
      expect({:error, :no_match, metrics}).to eq({:error, :no_match, 526})
    end

    it "returns :error for invalid image data" do
      expect(ImageDiff.compare(nil,nil)).to eq({:error, :invalid_input})
    end
  end
end
