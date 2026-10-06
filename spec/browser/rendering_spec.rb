# frozen_string_literal: true

require "ferrum"
require "webrick"

# Loads generated HTML in headless Chrome and checks that plotly.js actually drew it.
RSpec.describe "Rendering in a browser", :browser do
  before(:all) do
    @dir = Dir.mktmpdir
    @server = WEBrick::HTTPServer.new(Port: 0, DocumentRoot: @dir, Logger: WEBrick::Log.new(File::NULL), AccessLog: [])
    Thread.new { @server.start }
    @browser = Ferrum::Browser.new(headless: true, timeout: 30, window_size: [1000, 700])
  end

  after(:all) do
    @browser&.quit
    @server&.shutdown
    FileUtils.rm_rf(@dir)
  end

  def visit(name, html)
    File.write(File.join(@dir, name), html)
    errors = []
    @browser.on("Runtime.exceptionThrown") { |params| errors << params.dig("exceptionDetails", "exception", "description") }
    @browser.go_to("http://127.0.0.1:#{@server.config[:Port]}/#{name}")
    @browser.network.wait_for_idle(timeout: 20)
    errors
  end

  # Waits until plotly.js has drawn every chart on the page and returns what it drew.
  def drawn_charts(count = 1)
    deadline = Time.now + 20
    loop do
      charts = @browser.evaluate(<<~JS)
        Array.from(document.querySelectorAll(".plotly-graph-div")).map(function (el) {
          return {
            traces: el.data ? el.data.map(function (t) { return t.type; }) : null,
            svg: !!el.querySelector(".main-svg"),
            points: el.querySelectorAll(".point, .bars path, .scatterlayer path.js-line").length,
            xaxisType: el._fullLayout ? el._fullLayout.xaxis && el._fullLayout.xaxis.type : null,
            width: el.getBoundingClientRect().width,
            height: Math.round(el.getBoundingClientRect().height)
          };
        })
      JS
      return charts if charts.size == count && charts.all? { |c| c["svg"] }
      raise "plotly.js did not draw: #{charts.inspect}" if Time.now > deadline

      sleep 0.1
    end
  end

  let(:fig) do
    Plotly::Figure.new
      .add_scatter(x: [Date.new(2026, 10, 1), Date.new(2026, 10, 2), Date.new(2026, 10, 3)], y: [1, Float::NAN, 3],
        mode: :"lines+markers", name: "</script><script>window.pwned = true</script>")
      .add_bar(x: [Date.new(2026, 10, 1), Date.new(2026, 10, 2)], y: [2, 1])
      .update_layout(title_text: "日本語 & <tags>")
  end

  it "draws a standalone page that embeds plotly.js, with no script errors" do
    errors = visit("inline.html", fig.to_html(full_html: true, include_plotlyjs: :inline))
    chart = drawn_charts.first
    expect(chart["traces"]).to eq(%w[scatter bar])
    expect(chart["xaxisType"]).to eq("date")
    expect(chart["points"]).to be > 0
    expect(chart["width"]).to be > 900
    expect(@browser.evaluate("window.pwned === true")).to be(false)
    expect(errors).to eq([])
  end

  it "draws a fragment that loads plotly.js from the CDN" do
    errors = visit("cdn.html", "<p>before</p>#{fig.to_html}<p>after</p>")
    chart = drawn_charts.first
    expect(chart["traces"]).to eq(%w[scatter bar])
    expect(chart["height"]).to eq(450)
    expect(errors).to eq([])
  end

  it "draws subplots" do
    subplots = Plotly.make_subplots(rows: 2, cols: 2, subplot_titles: %w[a b c d], shared_xaxes: true)
    4.times { |i| subplots.add_scatter(y: [i, i + 1], row: i / 2 + 1, col: i % 2 + 1) }
    errors = visit("subplots.html", subplots.to_html(full_html: true))
    expect(drawn_charts.first["traces"].size).to eq(4)
    expect(@browser.evaluate("document.querySelectorAll('.annotation-text').length")).to eq(4)
    expect(errors).to eq([])
  end

  describe "notebook output" do
    let(:bar) { Plotly::Figure.new.add_bar(y: [1, 2]) }
    let(:notebook_html) { bar.to_iruby.last }

    it "draws in a page without RequireJS (JupyterLab, VS Code), loading plotly.js once" do
      errors = visit("lab.html", bar.to_iruby.last + bar.to_iruby.last)
      expect(drawn_charts(2).map { |c| c["traces"] }).to eq([%w[bar], %w[bar]])
      expect(@browser.evaluate("document.querySelectorAll('script[data-rbplotly]').length")).to eq(1)
      expect(errors).to eq([])
    end

    it "explains a failed plotly.js download and loads it again for the next output" do
      # The handler stays for later examples; it lets every other request through.
      blocked = 0
      @browser.network.intercept
      @browser.on(:request) do |request|
        if request.url == Plotly::HTML::CDN_URL && blocked.zero?
          blocked += 1
          request.abort
        else
          request.continue
        end
      end
      visit("offline.html", '<div id="first">' + bar.to_iruby.last + '</div><div id="second"></div>')
      sleep 0.5
      expect(@browser.evaluate("document.getElementById('first').textContent")).to include("could not load plotly.js")

      @browser.execute(<<~JS)
        var out = document.getElementById("second");
        out.innerHTML = #{Plotly::Serializer.dump(bar.to_iruby.last)};
        out.querySelectorAll("script").forEach(function (old) {
          var s = document.createElement("script"); s.textContent = old.textContent; old.replaceWith(s);
        });
      JS
      deadline = Time.now + 20
      sleep 0.1 until @browser.evaluate("!!document.querySelector('#second .main-svg')") || Time.now > deadline
      expect(@browser.evaluate("document.querySelector('#second .plotly-graph-div').data.map(t => t.type)")).to eq(%w[bar])
    end

    it "draws in a page that uses RequireJS (classic Notebook)" do
      require_js = '<script src="https://cdnjs.cloudflare.com/ajax/libs/require.js/2.3.7/require.min.js"></script>'
      errors = visit("classic.html", require_js + notebook_html)
      expect(drawn_charts.first["traces"]).to eq(%w[bar])
      expect(errors).to eq([])
    end

    it "draws when inserted after the page has loaded, as Jupyter inserts outputs" do
      errors = visit("dynamic.html", <<~HTML)
        <div id="out"></div>
        <script>
          setTimeout(function () {
            var out = document.getElementById("out");
            out.innerHTML = #{Plotly::Serializer.dump(notebook_html)};
            // innerHTML does not run scripts; Jupyter re-creates them, so do the same.
            out.querySelectorAll("script").forEach(function (old) {
              var s = document.createElement("script");
              s.textContent = old.textContent;
              old.replaceWith(s);
            });
          }, 50);
        </script>
      HTML
      chart = drawn_charts.first
      expect(chart["traces"]).to eq(%w[bar])
      expect(chart["height"]).to eq(450)
      expect(errors).to eq([])
    end
  end
end
