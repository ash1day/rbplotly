# frozen_string_literal: true

require "json"
require_relative "../../lib/rbplotly"

# Builds every figure in plotly.js' own test mocks with validation on and groups the
# rejections by attribute path. Mocks also contain deliberately sloppy input that plotly.js
# silently drops (legacy names, out-of-range values); a new kind of rejection on a valid
# attribute is a false positive to fix.
module MockSweep
  module_function

  def run(dir)
    rejected = Hash.new { |h, k| h[k] = [] }
    files = Dir[File.join(dir, "*.json")].sort
    files.each do |file|
      mock = JSON.parse(File.read(file))
      Plotly::Figure.new(data: mock["data"] || [], layout: mock["layout"] || {}, config: mock["config"] || {})
    rescue Plotly::ValidationError, ArgumentError => e
      path, reason = e.message.split(": ", 2)
      rejected["#{path.gsub(/\[\d+\]/, "[]")}: #{reason[0, 100]}"] << File.basename(file)
    end
    [files.size, rejected]
  end
end
