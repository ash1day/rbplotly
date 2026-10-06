# frozen_string_literal: true

require "cgi"
require "fileutils"
require_relative "../../lib/rbplotly"

# Runs every script in examples/ and builds site/: one page with each chart next to its code.
module Gallery
  Example = Struct.new(:name, :title, :summary, :code, :figure)

  module_function

  def examples
    Dir["examples/*.rb"].sort.map do |path|
      code = File.read(path)
      scope = Object.new.instance_eval { binding }
      scope.eval(code, path)
      figure = scope.local_variable_get(:fig)
      name = File.basename(path, ".rb")
      summary = code[/\A# (.+)$/, 1]
      Example.new(name, name.tr("_", " ").capitalize, summary, code, figure)
    end
  end

  def build(dir)
    FileUtils.mkdir_p(dir)
    list = examples
    File.write(File.join(dir, "index.html"), page(list))
    list.each { |ex| ex.figure.write_html(File.join(dir, "#{ex.name}.html"), include_plotlyjs: :cdn) }
    list
  end

  def page(list)
    sections = list.map do |ex|
      <<~HTML
        <section id="#{ex.name}">
          <h2><a href="##{ex.name}">#{CGI.escapeHTML(ex.title)}</a></h2>
          <p>#{CGI.escapeHTML(ex.summary.to_s)} <a href="#{ex.name}.html">Open full size</a> ·
             <a href="https://github.com/ash1day/rbplotly/blob/master/examples/#{ex.name}.rb">Source</a></p>
          <div class="chart">#{ex.figure.to_html(include_plotlyjs: false, height: ex.figure.layout.fetch("height", 460), div_id: "chart-#{ex.name}")}</div>
          <pre><code>#{CGI.escapeHTML(ex.code)}</code></pre>
        </section>
      HTML
    end
    nav = list.map { |ex| %(<a href="##{ex.name}">#{CGI.escapeHTML(ex.title)}</a>) }.join("\n")

    <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>rbplotly gallery</title>
      <meta name="description" content="Interactive Plotly.js charts from Ruby: examples with their source code.">
      <style>
        :root { --fg: #1f2328; --muted: #59636e; --line: #d1d9e0; --code: #f6f8fa; --link: #0969da; --bg: #ffffff; }
        @media (prefers-color-scheme: dark) {
          :root { --fg: #e6edf3; --muted: #9198a1; --line: #3d444d; --code: #151b23; --link: #4493f8; --bg: #0d1117; }
        }
        * { box-sizing: border-box; }
        body { margin: 0; font: 16px/1.6 -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif; color: var(--fg); background: var(--bg); }
        main { max-width: 1040px; margin: 0 auto; padding: 32px 16px 80px; }
        header h1 { font-size: 2rem; margin: 0 0 4px; }
        header p { color: var(--muted); margin: 0 0 16px; }
        a { color: var(--link); text-decoration: none; }
        a:hover { text-decoration: underline; }
        nav { display: flex; flex-wrap: wrap; gap: 8px 16px; padding: 12px 0 8px; border-bottom: 1px solid var(--line); }
        section { padding-top: 40px; }
        h2 { font-size: 1.35rem; margin: 0 0 4px; }
        h2 a { color: inherit; }
        section > p { color: var(--muted); margin: 0 0 12px; }
        .chart { background: #fff; border: 1px solid var(--line); border-radius: 8px; overflow: hidden; }
        pre { background: var(--code); border: 1px solid var(--line); border-radius: 8px; padding: 16px; overflow-x: auto; font-size: 13px; line-height: 1.5; margin: 12px 0 0; }
        code { font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; }
        .install { display: inline-block; background: var(--code); border: 1px solid var(--line); border-radius: 6px; padding: 4px 10px; }
      </style>
      <script src="#{Plotly::HTML::CDN_URL}" charset="utf-8"></script>
      </head>
      <body>
      <main>
        <header>
          <h1>rbplotly</h1>
          <p>Interactive <a href="https://plotly.com/javascript/">Plotly.js</a> charts from Ruby.
             Every chart below is drawn by the Ruby code under it (plotly.js #{Plotly::PLOTLY_JS_VERSION}, rbplotly #{Plotly::VERSION}).</p>
          <p><code class="install">gem install rbplotly</code> ·
             <a href="https://github.com/ash1day/rbplotly">GitHub</a> ·
             <a href="https://rubydoc.info/gems/rbplotly">API docs</a></p>
        </header>
        <nav>
      #{nav}
        </nav>
      #{sections.join}
      </main>
      </body>
      </html>
    HTML
  end
end
