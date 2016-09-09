require 'plotly/castable'
require 'plotly/marker'

module Plotly
  class Data
    include Castable

    attr_accessor :x, :y, :z, :values, :labels, :mode, :type, :name, :colorscale, :marker

    # @option opts [Array] x
    # @option opts [Array] y
    # @option opts [Array] z
    # @option opts [Array] values
    # @option opts [Array] labels
    # @option opts [String] mode
    # @option opts [String] type
    # @option opts [String] name
    # @option opts [Array] colorscale
    # @option opts [Hash or Plotly::Marker] marker
    def initialize(opts = {})
      opts.each do |k, v|
        v.convert_to(Plotly::Marker) if k == marker
        instance_variable_set("@#{k}", v)
      end
    end

    def marker=(marker)
      marker.convert_to(Plotly::Marker)
      @marker = marker
    end
  end
end
