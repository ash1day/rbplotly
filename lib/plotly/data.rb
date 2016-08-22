require 'plotly/castable'

module Plotly
  class Data
    attr_accessor :x, :y, :type, :mode, :name
    include Castable

    # @option x [Array]
    # @option y [Array]
    # @option type [String]
    # @option mode [String]
    # @option name [String]
    def initialize(x: nil, y: nil, type: nil, mode: nil, name: nil)
      @x = x
      @y = y
      @type = type
      @mode = mode
      @name = name

    end
  end
end
