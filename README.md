# Leeloo - Leela's younger cousin

> from the 5th Element of Elixir ;)

**Leela's cousin**, fooling around with PNGs and basic Imagemagick, using Elixir .. of course

## Scope

 - find the differences between two (.PNG) images and obtain a third image containing the visual differences.
 - create a simple Elixir web microservice, for prototyping and testing purposes.
 - tinkering at cool stuff

For testing, we'll use these two images:

|image 1|  |image 2|
|--------|---|-----|
|![](spec/fixtures/p1.png) | vs. | ![](spec/fixtures/p1_2.png)|

The prototype must successfully return the following:

- if the images match: `{"ok": "match"}`
- if the images are different (excerpt):
   `{"error": "no_match", "diff_metric": 526, "diff_visual": "data:image/png;base64,iVBORw0KGgII...=="}`
- if the images have different heights or widths: `{:error, :widths_or_heights_differ}`

The differences between the two test images should look like this, after processing:

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

	9 examples, 0 failures
	Finished in 1.41 seconds (0.43s on load, 0.97s on specs)
	Randomized with seed 577470

----------------
COV    FILE                                        LINES RELEVANT   MISSED
  0.0% lib/leeloo.ex                                  18        3        3
 77.8% lib/leeloo/api.ex                              60        9        2
 86.7% lib/leeloo/image_diff.ex                       48       15        2
[TOTAL]  74.1%
----------------
```

## Start the web server

```elixir
$ mix run --no-halt

23:43:16.398 [info]  Starting Elixir.Leeloo.Api with Cowboy on http://127.0.0.1:8080
```

`Leelo` is up and receiving requests at `http://127.0.0.1:8080`

Quick test:

```shell
$ curl http://127.0.0.1:8080/api/echo -X POST
```
The server will respond with: `{"echo":"Sup?!"}`

## Play with (:base64 encoded) images

Given you Base64 encoded the desired images and having the server running at `http://127.0.0.1:8080`, run the following simple test:

```shell
curl -H "Content-Type:application/json" -X POST http://127.0.0.1:8080/api/compare/png_strings \
  -d '{"images": {"reference" : "data:image/png;base64,iVBORw0KG...gg==", "comparison": "data:image/png;base64,iVBORw0KGgoRK5....CYII="}}'

```
(the example above is using the two **different** fixture images shown earlier, for testing)

Mind you, the `curl` above is truncated, for brevity purpose. Please see the [curl.txt](curl.txt) file, in the project's main folder, for the full command line.

With the specified curl from the example file, you'll get back information about the differences between the two given images. Leelo will return a json like this (excerpt):

```json
{"error":"no_match","diff_visual":"data:image/....==", "diff_metric":526}
```

and on the server console, you can see the logs:

```
12:02:55.049 [info]  POST /api/compare/png_strings
12:02:55.063 [info]  Sent 201 in 14ms
```

Ok, `14ms` it's a lot for an Elixir app, but don't forget that we run an external command under the hood; imagemagick

That's it, for this prototype.

Enjoy!
