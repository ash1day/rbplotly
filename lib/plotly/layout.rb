module Plotly
  class Layout
    ATTRS = %i(x_title y_title barmode).freeze
    attr_accessor(*ATTRS)

    def initialize(x_title: nil, y_title: nil, barmode: nil)
      @x_title = x_title
      @y_title = y_title
      @barmode = barmode
    end

    def to_h
      {
        xaxis: { title: @x_title },
        yaxis: { title: @y_title },
        barmode: @barmode
      }
    end
  end
end
