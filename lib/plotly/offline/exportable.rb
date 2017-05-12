require 'uuidtools'
require 'launchy'
require 'plotly/offline/html'

module Plotly
  module Offline
    module Exportable
      # for IRuby
      def show
        # @todo unless defined? IRuby
        html = create_html(@data, layout: @layout, embedded: true)
        IRuby.display(html)
      end

      # @param path [String]
      # @param open [Boolean]
      def generate_html(path: 'plot.html', open: true)
        html = create_html(@data, layout: @layout)
        File.write(path, html.render)
        Launchy.open(File.absolute_path(path)) if open
      end

      def to_html
        html = create_html(@data, layout: @layout, embedded: true)
        html.render
      end

      private

      def create_html(data, layout: {}, embedded: false)
        id = UUIDTools::UUID.random_create.to_s
        HTML.new(id, data.map(&:to_h), layout: layout.to_h, embedded: embedded)
      end
    end
  end
end
