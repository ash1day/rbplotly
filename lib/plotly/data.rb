module Plotly
  class Data
    attr_accessor :x, :y, :type, :mode

    def initialize(x: nil, y: nil, type: nil, mode: nil)
      @x = x
      @y = y
      @type = type
      @mode = mode
    end

    def to_h
      {
        x: @x,
        y: @y,
        type: @type,
        mode: @mode
      }
    end
  end
end
