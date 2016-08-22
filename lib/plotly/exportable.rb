module Plotly
  module Exportable
    # @option format [String]
    # @option path [String]
    # @option width [FIxnum]
    # @option height [FIxnum]
    # @option scale [FIxnum]
    # @option client [Plotly::Client]
    def download_image(format: :png, path: 'plot.png', client: ::Plotly.client,
                       width: nil, height: nil, scale: nil)
      payload = {
        figure: { data: @data.map(&:to_h), layout: @layout.to_h },
        format: format
      }
      payload[:height] = height unless height.nil?
      payload[:width]  = width  unless width.nil?
      payload[:scale]  = scale  unless scale.nil?

      res = client.conn.post('images', payload.to_json)
      IO.binwrite(path, res.body)
    end
  end
end
