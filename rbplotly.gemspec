# frozen_string_literal: true

require_relative "lib/plotly/version"

Gem::Specification.new do |spec|
  spec.name = "rbplotly"
  spec.version = Plotly::VERSION
  spec.authors = ["Yoshihiro Ashida"]
  spec.email = ["y4ashida@gmail.com"]

  spec.summary = "Interactive Plotly.js charts from Ruby, validated against the plotly.js schema"
  spec.description = <<~DESC.tr("\n", " ").strip
    Build Plotly.js figures with plain Ruby hashes, check every attribute against the
    plot schema of the bundled plotly.js release, and write self-contained HTML that
    works offline, in Rails views and in Jupyter (IRuby). No account or API key needed.
  DESC
  spec.homepage = "https://github.com/ash1day/rbplotly"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/blob/master/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "documentation_uri" => "https://rubydoc.info/gems/rbplotly",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["lib/**/*.{rb,json,js}", "README.md", "CHANGELOG.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]

  spec.add_dependency "json", ">= 2.7"
end
