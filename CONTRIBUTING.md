# Contributing

Bug reports, examples and pull requests are welcome. Please be kind; this project follows the
[Code of Conduct](CODE_OF_CONDUCT.md).

## Reporting a bug

Include the Ruby code that builds the figure, what you expected, and what happened (the
`Plotly::ValidationError` message or a screenshot). If the chart renders wrongly, check
whether the same JSON (`fig.to_json`) renders wrongly in plain plotly.js too; if it does, the
issue belongs to [plotly.js](https://github.com/plotly/plotly.js/issues).

## Setting up

```sh
bin/setup         # bundle install + download the pinned plotly.js (checksum-verified)
bundle exec rake  # specs and Standard (lint); no accounts or API keys needed
```

`bundle exec rake spec:browser` renders the generated HTML in headless Chrome and checks that
plotly.js drew it, including the notebook output. It needs Chrome and network access (the
fragment and notebook outputs load plotly.js from its CDN).

Notebook output is covered by `spec/browser` with pages that behave like Jupyter. When you
change it, also check a real notebook: install `jupyterlab` and the `iruby` gem, run
`iruby register`, and display a figure in JupyterLab.

## How the code is organized

| File | Role |
| --- | --- |
| `lib/plotly/schema.rb` | Reads `schema/plot-schema.json`, the attribute tree of the pinned plotly.js |
| `lib/plotly/attributes.rb` | Normalizes and validates attribute hashes against that tree |
| `lib/plotly/figure.rb` | The public `Figure` API |
| `lib/plotly/subplots.rb` | `Plotly.make_subplots` and the grid math |
| `lib/plotly/serializer.rb` | Ruby values to plotly.js JSON, safe inside `<script>` |
| `lib/plotly/html.rb` | HTML documents, fragments and notebook output |
| `rakelib/` | plotly.js download, schema generation, gallery and README images |

`lib/plotly/schema/plot-schema.json` is generated: change `rakelib/support/schema_pruner.rb`
and run `rake schema:generate` instead of editing it. CI fails if it is out of date.

## Changes

- Add or update specs with the change. Behavior visible in a browser deserves a case in
  `spec/browser/`.
- Keep runtime dependencies at zero beyond `json`.
- Add a line to the `Unreleased` section of `CHANGELOG.md` for user-visible changes.
- New examples go in `examples/`; they appear in the gallery automatically. Use synthetic data.

## Updating plotly.js

1. Set `Plotly::PLOTLY_JS_VERSION` in `lib/plotly/version.rb`.
2. `bundle exec rake plotlyjs:checksum` and put the result in `PLOTLY_JS_SHA256` in
   `rakelib/plotlyjs.rake`.
3. `bundle exec rake schema:generate plotlyjs:fetch` and read the schema diff for removed or
   renamed attributes; those are breaking changes for users.
4. `bundle exec rake && bundle exec rake spec:browser gallery`, and look at the gallery.

## Releasing

1. Update `Plotly::VERSION` and move the `Unreleased` notes in `CHANGELOG.md` under the version.
2. Commit, then tag `vX.Y.Z` and push the tag. The release workflow builds the gem (with the
   bundled plotly.js) and publishes it to RubyGems through trusted publishing.
