require 'plotly/castable'
require 'plotly/line'

module Plotly
  class Marker
    include Castable

    ATTRS = %i(size color line).freeze
    attr_accessor(*ATTRS)

    # @option opts [Fixnum] size
    # @option opts [String] color e.g.'rgba(0, 0, 200, .5)'
    # @option opts [Hash or Plotly::Data::Marker::Line] line
    def initialize(opts)
      return unless opts.is_a?(Hash)

      opts.each do |k, v|
        v.convert_to(Plotly::Data::Marker::Line) if k.to_sym == :line
        instance_variable_set("@#{k}", v)
      end
    end
  end
end
