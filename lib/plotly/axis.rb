require 'plotly/castable'

module Plotly
  class Axis
    include Castable

    ATTRS = %i(title range).freeze
    attr_accessor(*ATTRS)

    def initialize(opts)
      return unless opts.is_a?(Hash)
      opts.each { |k, v| instance_variable_set("@#{k}", v) }
    end
  end
end
