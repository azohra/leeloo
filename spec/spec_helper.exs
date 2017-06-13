Maru.Test.start()

ESpec.configure fn(config) ->
  config.before fn(tags) ->
    {
      :shared,
      image_png_reference_path: "spec/fixtures/p1.png",
      image_png_comparison_path: "spec/fixtures/p1_2.png",
      tags: tags
    }
  end

  config.finally fn(_shared) ->
    :ok
  end
end
