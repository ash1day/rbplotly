require 'plotly/castable'

module Plotly
  class Data
    include Castable

    attr_accessor :x, :y, :z, :values, :labels, :mode, :type, :name, :colorscale

    # @option opts [Array] x
    # @option opts [Array] y
    # @option opts [Array] z
    # @option opts [Array] values
    # @option opts [Array] labels
    # @option opts [String] mode
    # @option opts [String] type
    # @option opts [String] name
    # @option opts [Array] colorscale
    def initialize(opts = {})
      opts.each { |k, v| instance_variable_set("@#{k}", v) }
    end
  end
end
