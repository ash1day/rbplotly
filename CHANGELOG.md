# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.0.1] - 2026-10-07

### Added

- Relative subplot sizes through `column_widths` and `row_heights`, and per-cell right y
  axes through `specs: [[{secondary_y: true}]]`. Trace placement, trace updates and y-axis
  updates accept `secondary_y`; existing primary axis numbering is preserved.
- Animation frames through `Figure.new(frames:)`, `add_frame` and `frames=`, with validation
  of partial trace/layout updates and inclusion in JSON output. HTML and notebook output
  register frames and start playback; `to_html` and `write_html` accept `auto_play` and
  `animation_opts`.
- Runnable examples for secondary axes and animation.

### Fixed

- Require `json >= 2.9` to avoid the older `script_safe` bug that corrupts characters such
  as `瀨` and `倩` in chart labels and JSON output.
- Reject negative, non-finite and out-of-range subplot spacing instead of silently
  overlapping or collapsing cells; reject invalid row/column counts before calculating defaults.

## [1.0.0] - 2026-10-07

A rewrite. Figures are now plain hashes checked against the plot schema of a pinned
plotly.js release, instead of hand-written classes that covered a few attributes.

### Added

- `Plotly::Figure` with `add_trace`, an `add_<type>` helper for each of plotly.js' 47 trace
  types, `update_layout`, `update_traces` (with `selector:`), `update_xaxes`, `update_yaxes`
  and `update_config`.
- Validation of attribute names, enumerated values, flag lists, booleans and number ranges
  against plotly.js 4.1.2, with the attribute path and a spelling suggestion in
  `Plotly::ValidationError`. `validate: false` turns it off.
- Underscore paths for nested attributes: `marker_line_width: 2`.
- `Plotly.make_subplots` with shared axes and subplot titles; `row:` / `col:` on trace and
  axis updates.
- `include_plotlyjs:` (`:cdn`, `:inline`, `false` or a URL), `div_id:`, `width:`, `height:`
  and `full_html:` on `to_html`; `write_html` embeds plotly.js by default so files work offline.
- `to_json` / `to_h`. Dates and times, `NaN`, ranges, `BigDecimal` and objects with `#to_a`
  (Numo, Polars, Daru columns) are converted to what plotly.js expects.
- An example gallery (`rake gallery`) and specs that draw the generated HTML in headless Chrome.

### Changed

- Requires Ruby 3.3 or later.
- Bundles plotly.js 4.1.2 (was 1.16.2). The CDN URL is pinned to the same release instead of
  `plotly-latest`, which stopped updating at 1.x.
- JSON inside `<script>` is escaped so that strings such as `"</script>"` cannot end the
  element.
- Charts resize with their container through plotly.js' `responsive` config.
- No runtime dependencies besides `json` (`faraday`, `uuidtools` and `launchy` are gone).

### Fixed

- Charts render in JupyterLab: notebook output no longer relies on RequireJS, and
  `to_iruby_mimebundle` keeps IRuby 0.8 from choosing `to_html`, whose script would run
  before plotly.js loads ([#10](https://github.com/ash1day/rbplotly/issues/10)).
- Subplots are supported ([#8](https://github.com/ash1day/rbplotly/issues/8)).
- Tests run without a plot.ly account, and the README explains how to run them
  ([#9](https://github.com/ash1day/rbplotly/issues/9)).

### Deprecated

- `Plotly::Plot`. It still accepts `data:` / `layout:` and `generate_html(path:, open:)`,
  and prints a warning; use `Plotly::Figure` and `write_html`. It will be removed in 2.0.

### Removed

- `Plotly.auth`, `Plotly::Client` and `#download_image`, which used the plot.ly cloud API.
- The attribute classes (`Plotly::Data`, `Layout`, `Axis`, `Marker`, `Line`) and
  `Object#convert_to`, which was added to every object.

## [0.1.2] - 2017-05-24

The last 0.x release. See the [git history](https://github.com/ash1day/rbplotly/commits/v0.1.2).

[Unreleased]: https://github.com/ash1day/rbplotly/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/ash1day/rbplotly/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/ash1day/rbplotly/compare/v0.1.2...v1.0.0
[0.1.2]: https://github.com/ash1day/rbplotly/releases/tag/v0.1.2
