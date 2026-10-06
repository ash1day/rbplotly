# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "bigdecimal" # used by the specs; a bundled gem since Ruby 3.4
gem "rake", "~> 13.2"
gem "rspec", "~> 3.13"
gem "standard", "~> 1.40"
gem "yard", "~> 0.9"

group :browser do
  # Renders the generated HTML in headless Chrome (spec/browser). Needs a local Chrome.
  gem "ferrum", "~> 0.17"
  gem "webrick", "~> 1.9"
end
