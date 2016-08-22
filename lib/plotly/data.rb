require 'plotly/castable'

module Plotly
  class Data
    include Castable

    attr_accessor :x, :y, :values, :labels, :mode, :type, :name

    # @option opts [Array] x
    # @option opts [Array] y
    # @option opts [Array] values
    # @option opts [Array] labels
    # @option opts [String] mode
    # @option opts [String] type
    # @option opts [String] name
    def initialize(opts = {})
      opts.each { |k, v| instance_variable_set("@#{k}", v) }
    end
  end
end
