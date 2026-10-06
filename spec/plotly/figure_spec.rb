# frozen_string_literal: true

RSpec.describe Plotly::Figure do
  describe ".new" do
    it "builds traces and layout from hashes" do
      fig = described_class.new(
        data: [{type: :bar, x: %w[a b], y: [1, 2], marker_color: "teal"}],
        layout: {title_text: "Sales"}
      )
      expect(fig.data).to eq([{"type" => "bar", "x" => %w[a b], "y" => [1, 2], "marker" => {"color" => "teal"}}])
      expect(fig.layout).to eq("title" => {"text" => "Sales"})
    end

    it "treats a trace without a type as a scatter trace, as plotly.js does" do
      expect(described_class.new(data: [{y: [1]}]).data.first["type"]).to eq("scatter")
    end

    it "rejects unknown trace types even when validation is off" do
      expect { described_class.new(data: [{type: :scater}], validate: false) }
        .to raise_error(Plotly::ValidationError, 'data[0].type: "scater" is not a plotly.js trace type. Did you mean "scatter"?')
    end

    it "requires data to be an Array of traces" do
      expect { described_class.new(data: {type: :bar}) }.to raise_error(ArgumentError, /data must be an Array of trace Hashes/)
    end

    it "raises validation errors even when Ruby runs without did_you_mean" do
      script = 'require "rbplotly"; begin; Plotly::Figure.new(layout: {widht: 1}); rescue Plotly::ValidationError => e; print e.message; end'
      output = IO.popen([RbConfig.ruby, "--disable-did_you_mean", "-I", File.expand_path("../../lib", __dir__), "-e", script], err: [:child, :out], &:read)
      expect(output).to eq('layout.widht: layout has no attribute "widht". Did you mean "width"?')
    end

    it "validates attributes unless asked not to" do
      expect { described_class.new(layout: {widht: 300}) }.to raise_error(Plotly::ValidationError, /Did you mean "width"/)
      expect(described_class.new(layout: {widht: 300}, validate: false).layout).to eq("widht" => 300)
    end
  end

  describe "#add_trace and the add_<type> helpers" do
    it "appends traces and returns the figure so calls can be chained" do
      fig = described_class.new
        .add_trace(type: :scatter, y: [1, 2])
        .add_bar(y: [3, 4], name: "B")
        .add_heatmap(z: [[1, 2], [3, 4]])

      expect(fig.data.map { |t| t["type"] }).to eq(%w[scatter bar heatmap])
      expect(fig.data[1]).to eq("type" => "bar", "y" => [3, 4], "name" => "B")
    end

    it "accepts a hash as well as keyword arguments" do
      fig = described_class.new.add_trace({"type" => "pie", "values" => [1, 2]})
      expect(fig.data.first).to eq("type" => "pie", "values" => [1, 2])
    end

    it "defines a helper for every trace type in the schema" do
      Plotly::Schema.default.trace_types.each do |type|
        expect(described_class.method_defined?(:"add_#{type}")).to be(true), "add_#{type} is missing"
      end
    end
  end

  describe "#update_layout" do
    it "merges nested attributes into the existing layout" do
      fig = described_class.new(layout: {xaxis: {title_text: "x", type: :log}})
      fig.update_layout(xaxis_title_font_size: 18, height: 400)
      expect(fig.layout).to eq(
        "xaxis" => {"title" => {"text" => "x", "font" => {"size" => 18}}, "type" => :log},
        "height" => 400
      )
    end

    it "clears nested settings given nil, which plotly.js reads as unset" do
      fig = described_class.new(layout: {title_text: "x", xaxis_type: :log}).add_bar(y: [1], marker_color: "red")
      fig.update_layout(title: nil, xaxis: nil).update_traces(marker: nil)
      expect(fig.layout).to eq("title" => nil, "xaxis" => nil)
      expect(fig.data.first["marker"]).to be_nil
      expect(fig.to_json).to include('"title":null')
    end

    it "leaves the layout untouched when the update is invalid" do
      fig = described_class.new(layout: {height: 300})
      expect { fig.update_layout(height: 200, barmode: :piled) }.to raise_error(Plotly::ValidationError)
      expect(fig.layout).to eq("height" => 300)
    end
  end

  describe "#update_traces" do
    let(:fig) { described_class.new.add_bar(y: [1], name: "a").add_scatter(y: [2], name: "b").add_bar(y: [3], name: "c") }

    it "updates every trace" do
      fig.update_traces(opacity: 0.5)
      expect(fig.data.map { |t| t["opacity"] }).to eq([0.5, 0.5, 0.5])
    end

    it "updates only the traces matching a selector hash or block" do
      fig.update_traces({marker_color: "red"}, selector: {type: :bar})
      fig.update_traces(selector: ->(t) { t["name"] == "b" }, line_width: 3)

      expect(fig.data.map { |t| t["marker"] }).to eq([{"color" => "red"}, nil, {"color" => "red"}])
      expect(fig.data[1]["line"]).to eq("width" => 3)
    end

    it "validates against each trace's own schema" do
      expect { fig.update_traces(selector: {type: :scatter}, line_shape: :spline) }.not_to raise_error
      expect { fig.update_traces(line_shape: :spline) }.to raise_error(Plotly::ValidationError, /bar has no attribute "line"|line/)
    end
  end

  describe "#to_h and #to_json" do
    it "returns the figure as plotly.js reads it" do
      fig = described_class.new(data: [{y: [1, Float::NAN]}], layout: {title_text: :Hi})
      expect(fig.to_h).to eq("data" => [{"type" => "scatter", "y" => [1, Float::NAN]}], "layout" => {"title" => {"text" => :Hi}})
      expect(fig.to_json).to eq('{"data":[{"type":"scatter","y":[1,null]}],"layout":{"title":{"text":"Hi"}}}')
    end

    it "round-trips through JSON" do
      fig = described_class.new(data: [{type: :bar, y: [1]}], layout: {height: 300})
      copy = described_class.new(**JSON.parse(fig.to_json, symbolize_names: true))
      expect(copy.to_json).to eq(fig.to_json)
    end
  end

  it "summarizes itself in #inspect" do
    fig = described_class.new.add_bar(y: [1]).add_scatter(y: [2]).update_layout(height: 300)
    expect(fig.inspect).to eq("#<Plotly::Figure data=[bar, scatter] layout=[height]>")
  end
end
