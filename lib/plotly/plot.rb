require 'plotly/data'
require 'plotly/layout'
require 'plotly/offline/exportable'

module Plotly
  class Plot
    include Offline::Exportable

    # @!attribute [r] data
    #   @return [Array] the list of data
    # @!attribute [r] layout
    #   @return [Plotly::Layout]
    attr_reader :data, :layout

    # @option data [Array] list of Hash or Plotly::Data objects
    # @option layout [Hash or Plotly::Layout]
    def initialize(data: [], layout: {})
      @data   = data.map { |d| d.is_a?(Hash) ? Data.new(d) : d }
      @layout = layout.convert_to(Plotly::Layout)
    end

    # @param data [Plotly::Data or Hash]
    def add_data(data = Data.new)
      @data.push begin
        case data
        when Data then data
        when Hash then Data.new(data)
        end
      end
    end

    # @todo add remove_data method

    # @param data [Array] list of Hash or Plotly::Data objects
    def data=(data)
      raise unless data.is_a?(Array)
      @data = data.map { |d| d.convert_to(Plotly::Data) }
    end

    # @param layout [Hash or Plotly::Layout]
    def layout=(layout)
      @layout = layout.convert_to(Plotly::Layout)
    end
    def download_image(format, path, client: ::Plotly.client)
      payload = {
        figure: {
          data:   @data.map(&:to_h),
          layout: @layout.to_h
        },
        format: format
      }.to_json

      res = client.conn.post('images', payload)
      IO.binwrite(path, res.body)
    end
  end
end
