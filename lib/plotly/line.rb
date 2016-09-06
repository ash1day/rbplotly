require 'plotly/castable'

module Plotly
  class Line
    include Castable

    ATTRS = %i(width color).freeze
    attr_accessor(*ATTRS)

    # @option opts [Fixnum] width
    # @option opts [String] color 'rgba(0, 0, 200, .5)'
    def initialize(opts)
      return unless opts.is_a?(Hash)
      opts.each { |k, v| instance_variable_set("@#{k}", v) }
    end
  end
end
