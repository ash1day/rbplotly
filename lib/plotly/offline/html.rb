require 'erb'
require 'json'

module Plotly
  module Offline
    class HTML
      DEFAULT_CONFIG    = { linkText: 'Export to plot.ly', showLink: true }.freeze
      PLOTLY_JS_CDN_URL = 'https://cdn.plot.ly/plotly-latest.min'.freeze
      LOCAL_PLOTLY_JS   = File.read(File.expand_path('../plotly.min.js', __FILE__))

      # @param id [String]
      # @param data [Array]
      # @option layout [Hash]
      # @option config [Hash]
      # @option embedded [Boolean]
      def initialize(id, data, layout: {}, config: DEFAULT_CONFIG, embedded: false)
        @id       = id
        @data     = data
        @layout   = layout
        @config   = config
        @embedded = embedded
      end

      # @return [String] HTML document
      def render
        template_name = @embedded ? :body : :plot
        template = template_for(template_name)
        erb = ERB.new(template)
        erb.result(binding)
      end

      # This method is used to embed plots into IRuby notebooks.
      # @return [Array]
      def to_iruby
        ['text/html', render]
      end

      private

      def template_for(name)
        template_path = File.expand_path("../templates/#{name}.erb", __FILE__)
        File.read(template_path)
      end
    end
  end
end
