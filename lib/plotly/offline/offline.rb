require 'uuidtools'
require 'launchy'
require 'plotly/offline/html'

module Plotly
  module Offline
    class << self
      # @param data [Array]
      # @param layout [Hash]
      # @param path [String]
      # @param open [Boolean]
      def plot(data, layout: {}, path: 'plot.html', open: true)
        html = create_html(data, layout: layout)
        p html.render.class
        File.write(path, html.render)
        Launchy.open(path) if open
      end

      # @param data [Array]
      # @param layout [Hash]
      def iplot(data, layout: {})
        html = create_html(data, layout: layout, embedded: true)
        IRuby.display(html)
      end

      private

      def create_html(data, layout: {}, embedded: false)
        id = UUIDTools::UUID.random_create.to_s
        HTML.new(id, data, layout: layout, embedded: embedded)
      end
    end
  end
end
