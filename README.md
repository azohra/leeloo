# Leeloo

Small Elixir web aplication using [ImageMagick](http://www.imagemagick.org/script/index.php) (*compare*) to mathematically and visually annotate the difference between two images (of type `.PNG`)

## Scope

 - find the differences between two (.PNG) images and obtain a third image containing the visual differences, when they differ.
 - create a simple Elixir web microservice, using: [Maru](https://github.com/elixir-maru/maru), for prototyping and testing purposes.
 - tinkering at cool stuff

For testing, we'll use these two images:

|image 1|  |image 2|
|--------|---|-----|
|![](spec/fixtures/p1.png) | vs. | ![](spec/fixtures/p1_2.png)|

The web app must successfully return the following:

- `{"ok": "match"}` - when the two images are matching
- `{"transaction":"K1d5YW...","error":"no_match","diff_visual":"static/K1d5YW.png","diff_metric":526}` - when the images don't match (excerpt)
- `{:error, :widths_or_heights_differ}` when the two images have different heights or widths

The differences between our two test images should look like this:

![](spec/fixtures/p1vsp2.png)

This is a raw result, yet accurate! However, with ImageMagick, we can improve the resulting diff image even further, if need be.

## To test/dev/run the prototype

You'll need:

- elixir (~> 1.4)
- ImageMagick (~> 6.9.xx)
- curl (wget ...)


## Installation and test

pull the repo and then:

```shell
$ cd leeloo
$ mix do deps.get, compile
$ MIX_ENV=test mix espec --cover
```

If your environment is properly configured for Elixir development, then you should see approximately this, (excerpt)

```
.........

	6 examples, 0 failures
	Finished in 1.41 seconds (0.43s on load, 0.97s on specs)
	Randomized with seed 577470

----------------
COV    FILE                                        LINES RELEVANT   MISSED
  0.0% lib/leeloo.ex                                  18        3        3
 54.5% lib/leeloo/api.ex                              98       22       10
 85.7% lib/leeloo/image_diff.ex                       77       28        4
[TOTAL]  74.1%
----------------
```

## Start the web server

```elixir
$ mix run --no-halt

23:43:16.398 [info]  Starting Elixir.Leeloo.Api with Cowboy on http://127.0.0.1:4000
```

`Leelo` is up and receiving requests at: `http://127.0.0.1:4000/api`

Quick test:

```shell
$ curl http://127.0.0.1:4000/api
```
The server will respond with: `:ok`


## **Upload** and Compare

Upload two (.PNG) images and find if they match or not. Here's a `curl` command to get you started:

```shell
curl -X POST http://127.0.0.1:4000/api/compare/pngs \
  -F "images[reference]=@/path/to/file1.png" \
  -F "images[comparison]=@/path/to/file2.png"
```

When uploading images and Leeloo finds differences the server will respond with something like this:

```json
{
 "error": "no_match",
 "transaction":"K1d5YW...",
 "diff_visual":"static/K1d5YWpNQ2JEUT09.png", 
 "diff_metric":3120
}
```

Observe the `diff_visual` attribute! Leeloo saves the image resulting from comparing the two images, the reference image and the comparison one, and replies back with a link to the result. Basically, point your browser to `http://127.0.0.1:4000/static/K1d5YWpNQ2JEUT09.png`, to download the annotated difference between the two images.

### One more thing

When using the upload images api, you can also specify a new attribute: `fuzz`. Like this:

```shell
curl -X POST http://127.0.0.1:4000/api/compare/pngs \
  -F "images[fuzz]=10%" -F "images[reference]=@/path/to/file1.png" \
  -F "images[comparison]=@/path/to/file2.png"
```

Use this option to match colors that are close to the target color in RGB space and eventually ignore the colors that differ by a small amount. This option can account for these differences.

The `fuzz` distance can be a percentage of the maximum possible intensity; i.e. `20%`
If you set `fuzz` to 100%, then you'll get a `match` between two **different** images. Use it with care :)

`Leeloo` is currently under development.

Enjoy!
