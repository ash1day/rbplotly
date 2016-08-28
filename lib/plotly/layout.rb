require 'plotly/axis'
require 'plotly/castable'

module Plotly
  class Layout
    include Castable

    ATTRS = %i(title barmode xaxis yaxis width height).freeze
    attr_accessor(*ATTRS)

    AXISES = %i(xaxis yaxis).freeze

    # @option opts [String] title
    # @option opts [String] barmode
    # @option opts [Hash] xaxis
    # @option opts [Hash] yaxis
    def initialize(opts = {})
      return unless opts.is_a?(Hash)

      opts.each do |k, v|
        v.convert_to(Plotly::Axis) if AXISES.include?(k)
        instance_variable_set("@#{k}", v)
      end
    end

    AXISES.each do |axis_name|
      define_method("#{axis_name}=") do |axis|
        axis.convert_to(Plotly::Axis)
        instance_variable_set("@#{axis_name}", axis)
      end
    end
  end
end
