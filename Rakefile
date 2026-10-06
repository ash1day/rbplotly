# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "standard/rake"

RSpec::Core::RakeTask.new(:spec)

# The gem ships the plotly.js bundle for `include_plotlyjs: :inline`.
task build: "plotlyjs:fetch"
task spec: "plotlyjs:fetch"

task default: %i[spec standard]

namespace :spec do
  desc "Render generated HTML in headless Chrome (needs Chrome and network access)"
  task browser: "plotlyjs:fetch" do
    sh({"BROWSER" => "1"}, "bundle exec rspec spec/browser")
  end
end
