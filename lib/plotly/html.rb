# frozen_string_literal: true

require "cgi"
require "securerandom"

module Plotly
  # Renders figures as HTML.
  module HTML
    # The plotly.js build that `include_plotlyjs: :cdn` and notebook output load.
    CDN_URL = "https://cdn.plot.ly/plotly-#{PLOTLY_JS_VERSION}.min.js"
    # The same build, bundled in the gem for `include_plotlyjs: :inline`.
    BUNDLE_PATH = File.expand_path("assets/plotly.min.js", __dir__)
    # Config applied under the figure's own config.
    DEFAULT_CONFIG = {"responsive" => true}.freeze

    module_function

    # @param figure [Figure]
    # @param include_plotlyjs [:cdn, :inline, false, String] how the page gets plotly.js:
    #   the pinned CDN build, the bundled copy embedded in the page (works offline), not at
    #   all (the page already loads it), or from the given URL
    # @param full_html [Boolean] a whole document instead of a fragment
    # @param div_id [String, nil] id of the chart element; random by default
    # @param width [Integer, String, nil] element width (Integer means pixels); 100% by default
    # @param height [Integer, String, nil] element height; by default the layout height, else
    #   450px for a fragment (a percentage would collapse in a container of automatic height)
    #   and the whole window for a full document
    # @return [String]
    def render(figure, include_plotlyjs: :cdn, full_html: false, div_id: nil, width: nil, height: nil)
      id = div_id || "rbplotly-#{SecureRandom.uuid}"
      body = [
        plotlyjs_tag(include_plotlyjs),
        %(<div id="#{CGI.escapeHTML(id)}" class="plotly-graph-div" style="#{style(width, height || default_height(figure, full_html))}"></div>),
        "<script>\n#{draw_call(figure, id)}\n</script>"
      ].compact.join("\n")
      full_html ? document(figure, body) : body
    end

    # HTML for Jupyter frontends (classic Notebook, JupyterLab, VS Code): loads plotly.js once
    # per page and draws. plotly.js 3+ always registers itself as `window.Plotly`, never as an
    # AMD module, so a plain script element works even where the page uses RequireJS.
    def notebook(figure)
      id = "rbplotly-#{SecureRandom.uuid}"
      <<~HTML
        <div id="#{id}" class="plotly-graph-div" style="#{style(nil, default_height(figure, false))}"></div>
        <script>
        (function () {
          var src = "#{CDN_URL}";
          function draw(Plotly) {
            #{draw_call(figure, id).gsub("\n", "\n    ")}
          }
          if (window.Plotly) { draw(window.Plotly); return; }
          var script = document.querySelector('script[data-rbplotly="' + src + '"]');
          if (!script) {
            script = document.createElement("script");
            script.src = src;
            script.setAttribute("data-rbplotly", src);
            document.head.appendChild(script);
          }
          script.addEventListener("load", function () { draw(window.Plotly); });
          script.addEventListener("error", function () {
            var el = document.getElementById("#{id}");
            if (el) el.textContent = "rbplotly: could not load plotly.js from " + src;
          });
        })();
        </script>
      HTML
    end

    # @api private
    def draw_call(figure, id)
      config = DEFAULT_CONFIG.merge(figure.config)
      args = [id, figure.data, figure.layout, config].map { |arg| Serializer.dump(arg) }
      "Plotly.newPlot(#{args.join(", ")});"
    end

    def plotlyjs_tag(mode)
      case mode
      when :cdn then script_src(CDN_URL)
      when :inline then "<script>#{bundle.gsub("</script", "<\\/script")}</script>"
      when false, nil then nil
      when String then script_src(mode)
      else
        raise ArgumentError, "include_plotlyjs must be :cdn, :inline, false or a URL, got #{mode.inspect}"
      end
    end

    def script_src(url) = %(<script src="#{CGI.escapeHTML(url)}" charset="utf-8"></script>)

    def bundle
      @bundle ||= File.read(BUNDLE_PATH, encoding: "UTF-8")
    rescue Errno::ENOENT
      raise Error, "the bundled plotly.js is missing (#{BUNDLE_PATH}). In a git checkout, run " \
        "`bundle exec rake plotlyjs:fetch`, or use include_plotlyjs: :cdn"
    end

    def style(width, height)
      "height:#{length(height)};width:#{length(width || "100%")};"
    end

    def default_height(figure, full_html)
      layout_height = figure.layout["height"]
      return layout_height.round if layout_height.is_a?(Numeric)

      full_html ? "100%" : 450
    end

    def length(value) = value.is_a?(Integer) ? "#{value}px" : CGI.escapeHTML(value.to_s)

    def document(figure, body)
      title = figure.layout.dig("title", "text")
      title = (title.is_a?(String) || title.is_a?(Symbol)) ? title.to_s : "Plotly figure"
      <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>#{CGI.escapeHTML(title)}</title>
        <style>html, body { height: 100%; margin: 0; }</style>
        </head>
        <body>
        #{body}
        </body>
        </html>
      HTML
    end

    private_class_method :plotlyjs_tag, :script_src, :bundle, :style, :default_height, :length, :document
  end

  # Opens files in the desktop's default browser.
  module Browser
    module_function

    # @param path [String] absolute path of an HTML file
    def open(path)
      command = case RbConfig::CONFIG["host_os"]
      when /darwin/ then ["open", path]
      # Not `cmd /c start`: cmd.exe would interpret &, | and ^ in the file name.
      when /mswin|mingw|cygwin/ then ["explorer.exe", path]
      else ["xdg-open", path]
      end
      Process.detach(Process.spawn(*command, out: File::NULL, err: File::NULL))
    rescue SystemCallError
      warn "rbplotly: could not open a browser; the chart is at #{path}"
    end
  end
end
