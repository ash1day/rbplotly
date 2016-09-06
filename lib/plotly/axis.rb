require 'plotly/castable'

module Plotly
  class Axis
    include Castable

    ATTRS = %i(title range zeroline).freeze
    attr_accessor(*ATTRS)

    # @option opts [String] title
    # @option opts [Array] range
    # @option opts [Boolean] zeroline
    def initialize(opts)
      return unless opts.is_a?(Hash)
      opts.each { |k, v| instance_variable_set("@#{k}", v) }
    end
  end
end
