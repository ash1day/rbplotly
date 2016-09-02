require 'plotly/data'
require 'plotly/layout'
require 'plotly/exportable'
require 'plotly/offline/exportable'

module Plotly
  class Plot
    include Exportable
    include Offline::Exportable

    # @!attribute [r] data
    #   @return [Array] list of Plotly::Data objects
    # @!attribute [r] layout
    #   @return [Plotly::Layout]
    attr_reader :data, :layout

    # @option data [Array] list of Hash or Plotly::Data objects
    # @option layout [Hash or Plotly::Layout]
    def initialize(data: [], layout: {})
      @data   = data.map { |d| d.is_a?(Hash) ? Data.new(d) : d }
      @layout = layout.convert_to(Plotly::Layout)
    end

    # @param data [Array] list of Hash or Plotly::Data objects
    def data=(data)
      raise unless data.is_a?(Array)
      @data = data.map { |d| d.convert_to(Plotly::Data) }
    end

    # @param layout [Hash or Plotly::Layout]
    def layout=(layout)
      @layout = layout.convert_to(Plotly::Layout)
    end
  end
end
