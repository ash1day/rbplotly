# frozen_string_literal: true

module Plotly
  # The 0.x entry point, kept so existing code runs while it moves to {Figure}.
  # @deprecated Use {Figure}; `generate_html(path:, open:)` becomes `write_html(path, open:)`.
  class Plot < Figure
    def initialize(data: [], layout: {}, **options)
      warn "Plotly::Plot is deprecated and will be removed in rbplotly 2.0; use Plotly::Figure " \
        "(generate_html(path:) is now write_html(path))", uplevel: 1
      super
    end

    # @deprecated Use {Figure#write_html}.
    def generate_html(path: "plot.html", open: true)
      write_html(path, open: open)
    end
  end
end
