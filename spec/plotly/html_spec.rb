# frozen_string_literal: true

RSpec.describe "HTML output" do
  let(:fig) do
    Plotly::Figure.new(data: [{type: :bar, x: %w[a b], y: [1, 2]}], layout: {title_text: "Sales & <Costs>"})
  end
  let(:cdn) { "https://cdn.plot.ly/plotly-#{Plotly::PLOTLY_JS_VERSION}.min.js" }

  describe "#to_html" do
    it "returns a fragment that loads the pinned plotly.js from the CDN and draws the figure" do
      html = fig.to_html(div_id: "chart")
      expect(html).to include(%(<script src="#{cdn}" charset="utf-8"></script>))
      expect(html).to include(%(<div id="chart" class="plotly-graph-div"))
      expect(html).to include('Plotly.newPlot("chart", ' + Plotly::Serializer.dump(fig.data))
      expect(html).not_to include("<html")
    end

    it "makes the chart follow its container's size unless the config says otherwise" do
      expect(fig.to_html).to include('{"responsive":true}')
      expect(fig.update_config(responsive: false, displaylogo: false).to_html).to include('{"responsive":false,"displaylogo":false}')
    end

    it "embeds the bundled plotly.js with include_plotlyjs: :inline" do
      html = fig.to_html(include_plotlyjs: :inline)
      expect(html).to include("plotly.js v#{Plotly::PLOTLY_JS_VERSION}")
      expect(html).not_to include(cdn)
    end

    it "leaves loading plotly.js to the page with include_plotlyjs: false, or loads a given URL" do
      expect(fig.to_html(include_plotlyjs: false)).not_to include("<script src=")
      expect(fig.to_html(include_plotlyjs: "/assets/plotly.js")).to include('<script src="/assets/plotly.js" charset="utf-8"></script>')
    end

    it "rejects an unknown include_plotlyjs mode" do
      expect { fig.to_html(include_plotlyjs: :local) }.to raise_error(ArgumentError, /include_plotlyjs/)
    end

    it "gives every chart its own element id by default" do
      ids = 2.times.map { fig.to_html[/id="([^"]+)"/, 1] }
      expect(ids.uniq.size).to eq(2)
    end

    it "escapes the element id and user text" do
      html = Plotly::Figure.new(data: [{y: [1], name: "</script><script>alert(1)</script>"}]).to_html(div_id: %(a"b))
      expect(html).not_to include("<script>alert(1)")
      expect(html).not_to include("</script><script>")
      expect(html).to include(%(id="a&quot;b"))
    end

    it "gives a fragment the layout height, or 450px, so it has room in a container of automatic height" do
      expect(fig.to_html).to include('style="height:450px;width:100%;"')
      expect(fig.update_layout(height: 320).to_html).to include('style="height:320px;width:100%;"')
      expect(fig.to_iruby.last).to include('style="height:320px;width:100%;"')
    end

    it "fills the window in a full document unless the layout sets a height" do
      expect(Plotly::Figure.new.to_html(full_html: true)).to include('style="height:100%;width:100%;"')
    end

    it "sets the element size when width or height is given" do
      expect(fig.to_html(height: 300)).to include('style="height:300px;width:100%;"')
      expect(fig.to_html(width: "50%", height: "20em")).to include('style="height:20em;width:50%;"')
    end

    it "returns a full HTML document titled after the figure" do
      html = fig.to_html(full_html: true)
      expect(html).to start_with("<!DOCTYPE html>")
      expect(html).to include('<meta charset="utf-8">')
      expect(html).to include("<title>Sales &amp; &lt;Costs&gt;</title>")
    end
  end

  describe "#write_html" do
    it "writes a self-contained page that works offline and returns its path" do
      Dir.mktmpdir do |dir|
        path = fig.write_html(File.join(dir, "chart.html"))
        html = File.read(path)
        expect(html).to start_with("<!DOCTYPE html>")
        expect(html).to include("plotly.js v#{Plotly::PLOTLY_JS_VERSION}")
      end
    end

    it "does not open a browser unless asked" do
      Dir.mktmpdir do |dir|
        expect(Plotly::Browser).not_to receive(:open)
        fig.write_html(File.join(dir, "chart.html"))
      end
    end

    it "opens the written file in a browser with open: true" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "chart.html")
        expect(Plotly::Browser).to receive(:open).with(File.expand_path(path))
        fig.write_html(path, open: true)
      end
    end
  end

  describe "animation output" do
    before { fig.add_frame(name: "</script><script>bad()</script>", data: [{y: [3, 4]}]) }

    it "registers frames after drawing and then starts playback" do
      html = fig.to_html(div_id: "chart", animation_opts: {frame: {duration: 100}})
      expect(html).to include('.then(function () { return Plotly.addFrames("chart", ')
      expect(html).to include('.then(function () { return Plotly.animate("chart", null, {"frame":{"duration":100}}); })')
      expect(html).not_to include("<script>bad()")
    end

    it "registers frames without starting them when auto_play is false" do
      html = fig.to_html(auto_play: false)
      expect(html).to include("Plotly.addFrames")
      expect(html).not_to include("Plotly.animate")
      Dir.mktmpdir do |dir|
        file = fig.write_html(File.join(dir, "animation.html"), include_plotlyjs: false, auto_play: false)
        expect(File.read(file)).not_to include("Plotly.animate")
      end
    end

    it "includes animation frames in notebook output" do
      expect(fig.to_iruby.last).to include("Plotly.addFrames", "Plotly.animate")
    end
  end

  describe "notebooks" do
    it "renders as HTML that loads the pinned plotly.js once per page" do
      mime, html = fig.to_iruby
      expect(mime).to eq("text/html")
      expect(html).to include(%(var src = "#{cdn}"))
      expect(html).to include("script[data-rbplotly=")
      expect(html).not_to include("require")
    end

    it "says so in the output when plotly.js cannot be loaded, instead of leaving it blank" do
      expect(fig.to_iruby.last).to include('script.addEventListener("error"')
      expect(fig.to_iruby.last).to include("script.remove()")
    end

    it "gives IRuby a MIME bundle, which IRuby prefers over #to_html" do
      formats, metadata = fig.to_iruby_mimebundle(include: [])
      expect(formats.keys).to eq(["text/html"])
      expect(formats["text/html"]).to include("script[data-rbplotly=")
      expect(metadata).to eq({})
    end

    it "is displayed with IRuby when running in a notebook" do
      iruby = Module.new { def self.display(_obj) = nil }
      stub_const("IRuby", iruby)
      expect(iruby).to receive(:display).with(fig)
      expect(fig.show).to be_nil
    end

    it "opens a temporary page in the browser outside a notebook" do
      hide_const("IRuby")
      opened = nil
      allow(Plotly::Browser).to receive(:open) { |path| opened = path }
      path = fig.show
      expect(opened).to eq(path)
      expect(File.read(path)).to include("Plotly.newPlot")
    ensure
      File.delete(path) if path && File.exist?(path)
    end
  end
end
