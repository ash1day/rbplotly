# frozen_string_literal: true

require "tmpdir"
require_relative "plotly/version"

# Interactive Plotly.js charts from Ruby.
module Plotly
  # Raised when a figure uses an attribute or value that the bundled plotly.js schema rejects.
  class ValidationError < ArgumentError; end

  # Base class for other rbplotly errors.
  class Error < StandardError; end
end

require_relative "plotly/schema"
require_relative "plotly/attributes"
require_relative "plotly/serializer"
require_relative "plotly/html"
require_relative "plotly/frames"
require_relative "plotly/figure"
require_relative "plotly/subplots"
require_relative "plotly/plot"
