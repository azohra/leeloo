defmodule Leeloo.Instrumenter do
  use Prometheus.Metric

  def setup do
    Counter.declare([name: :images, help: "total images"])
    Counter.declare([name: :matching_images, help: "total matching images"])
    Counter.declare([name: :not_matching_images, help: "total not matching images"])

    Histogram.new([name: :image_compare_duration_milliseconds,
                   labels: [:method],
                   buckets: [100, 300, 500, 750, 1000, 2000, 3000, 5000, 6000, 20_000],
                   help: "Image compare execution time"])
  end

  def instrument_image_compare(time, method) do
    Histogram.dobserve([name: :image_compare_duration_milliseconds, labels: [method]], time)
  end

end
