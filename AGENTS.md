# Repository Guidelines

## Project Structure & Module Organization

rbplotly is a Ruby 3.3+ gem for building validated Plotly.js charts. `lib/rbplotly.rb` is the entry point; `lib/plotly/` contains the figure API, attribute validation, subplots, serialization, and HTML rendering. Unit specs live in `spec/plotly/`, browser integration specs in `spec/browser/`, and executable README checks in `spec/readme_spec.rb`.

Put runnable chart examples using synthetic data in `examples/`. `rakelib/` contains schema, download, gallery, and documentation tasks. README media lives in `docs/images/`; the generated gallery goes into ignored `site/`. The downloaded JavaScript bundle lives in `lib/plotly/assets/`.

## Build, Test, and Development Commands

- `bin/setup`: install gems and fetch the checksum-verified Plotly.js bundle.
- `bundle exec rake`: run non-browser specs and Standard lint.
- `bundle exec rspec spec/plotly/figure_spec.rb`: run focused specs after setup.
- `bundle exec rake spec:browser`: test rendering with headless Chrome; requires Chrome and network access.
- `bundle exec rake gallery`: build the example gallery in `site/` for local inspection.
- `bundle exec rake build`: build the gem into `pkg/`, including Plotly.js.
- `bundle exec rake schema:check`: verify the generated schema against the pinned upstream version.
- `bundle exec yard doc --fail-on-warning`: validate and generate API documentation.

## Coding Style & Naming Conventions

Follow Standard Ruby (`.standard.yml`), with two-space indentation and `# frozen_string_literal: true` in Ruby files. Use `snake_case` for files, methods, and variables, `CamelCase` for classes/modules, and uppercase constants. Document public APIs with YARD comments. Keep runtime dependencies limited to `json`.

## Testing Guidelines

Use RSpec 3 with `expect` assertions, descriptive examples, and `*_spec.rb` filenames mirroring source modules. Add regression coverage for behavior changes and browser specs for rendering changes. Specs run in randomized order; preserve the reported seed when investigating failures. No numeric coverage threshold is configured. Check notebook changes in a real JupyterLab/IRuby session too.

## Commit & Pull Request Guidelines

Recent commits use concise imperative subjects, such as “Fix subplot matching…”; follow that style. Describe the problem, resulting behavior, and validation in PRs. Link relevant issues and include screenshots for rendering changes. Add user-visible changes to `CHANGELOG.md` under `Unreleased`.

## Generated Files

Do not hand-edit `lib/plotly/schema/plot-schema.json`. Update `rakelib/support/schema_pruner.rb`, then run `bundle exec rake schema:generate`. Follow `CONTRIBUTING.md` when updating the pinned Plotly.js version.
