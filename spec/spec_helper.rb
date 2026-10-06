# frozen_string_literal: true

require "rbplotly"
require "tmpdir"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.order = :random
  Kernel.srand config.seed

  # spec/browser drives headless Chrome; run with `rake spec:browser` or BROWSER=1.
  config.filter_run_excluding(:browser) unless ENV["BROWSER"]
end
