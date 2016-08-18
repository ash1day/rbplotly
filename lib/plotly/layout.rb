module Plotly
  class Layout
    ATTRS = [:x_title, :y_title].freeze
    attr_accessor(*ATTRS)

    def initialize(x_title: nil, y_title: nil)
      @x_title = x_title
      @y_title = y_title
    end

    def to_h
      {
        xaxis: { title: @x_title },
        yaxis: { title: @y_title }
      }
    end
  end
end
