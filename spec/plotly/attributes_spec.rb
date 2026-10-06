# frozen_string_literal: true

RSpec.describe Plotly::Attributes do
  let(:schema) { Plotly::Schema.default }
  let(:scatter) { schema.trace("scatter") }

  def build(node, attrs, validate: true)
    described_class.build(node, attrs, path: "data[0]", validate: validate)
  end

  def error_for(node, attrs)
    build(node, attrs)
    raise "expected a validation error"
  rescue Plotly::ValidationError => e
    e.message
  end

  describe "normalization" do
    it "turns symbol keys into strings and keeps values as given" do
      expect(build(scatter, {x: [1, 2], mode: :lines})).to eq("x" => [1, 2], "mode" => :lines)
    end

    it "expands underscore paths into nested attributes" do
      expect(build(scatter, {marker_color: "red", marker_line_width: 2}))
        .to eq("marker" => {"color" => "red", "line" => {"width" => 2}})
    end

    it "keeps attribute names that contain an underscore" do
      expect(build(scatter, {error_x: {visible: true}, error_x_color: "red"}))
        .to eq("error_x" => {"visible" => true, "color" => "red"})
      expect(build(schema.layout, {paper_bgcolor: "white"})).to eq("paper_bgcolor" => "white")
    end

    it "merges underscore paths with an explicit nested hash" do
      expect(build(scatter, {marker: {size: 4}, marker_color: "red"}))
        .to eq("marker" => {"size" => 4, "color" => "red"})
    end

    it "normalizes every item of an array of objects" do
      result = build(schema.layout, {annotations: [{text: "a", font_size: 9}]})
      expect(result).to eq("annotations" => [{"text" => "a", "font" => {"size" => 9}}])
    end
  end

  describe "validation" do
    it "rejects unknown attributes and suggests the closest name" do
      expect(error_for(scatter, {markr: {}})).to eq(
        'data[0].markr: scatter has no attribute "markr". Did you mean "marker"?'
      )
    end

    it "reports the full path of a nested unknown attribute" do
      expect(error_for(scatter, {marker_colr: "red"})).to start_with('data[0].marker.colr: marker has no attribute "colr"')
    end

    it "rejects values outside an enumeration" do
      expect(error_for(schema.layout, {barmode: :stacked})).to eq(
        'data[0].barmode: "stacked" is not one of "stack", "group", "overlay", "relative". Did you mean "stack"?'
      )
    end

    it "accepts symbols and enumerations given by pattern" do
      expect { build(scatter, {xaxis: "x2", line_shape: :spline}) }.not_to raise_error
      expect { build(schema.layout, {xaxis2: {anchor: "y3", matches: "x"}}) }.not_to raise_error
    end

    it "checks each flag of a flaglist" do
      expect { build(scatter, {mode: :"markers+lines"}) }.not_to raise_error
      expect { build(scatter, {mode: "none"}) }.not_to raise_error
      expect(error_for(scatter, {mode: "line+markers"})).to eq(
        'data[0].mode: "line" is not a flag of mode. Did you mean "lines"? ' \
        'Join "lines", "markers", "text" with "+", or use "none"'
      )
    end

    it "checks booleans and numbers, including their range" do
      expect(error_for(scatter, {showlegend: "yes"})).to include("showlegend: expected true or false")
      expect(error_for(scatter, {visible: "yes"})).to include(%(visible: "yes" is not one of true, false, "legendonly"))
      expect(error_for(scatter, {opacity: 1.5})).to include("opacity: 1.5 is greater than the maximum 1")
      expect(error_for(scatter, {marker_size: "big"})).to include("marker.size: expected a number")
      expect { build(scatter, {marker_size: [4, 8, 12]}) }.not_to raise_error
    end

    it "checks array-like values given for attributes that accept one value per point" do
      expect { build(scatter, {marker_size: 4..6}) }.not_to raise_error
      expect(error_for(scatter, {marker_size: Set[4, "big"]})).to include('marker.size[1]: expected a number, got "big"')
    end

    it "explains that a string title must now be written as a hash" do
      expect(error_for(schema.layout, {title: "Sales"})).to include('use title: {text: "Sales"} or title_text: "Sales"')
    end

    it "requires arrays of objects to be arrays of hashes" do
      expect(error_for(schema.layout, {shapes: {type: "line"}})).to include("shapes: expected an Array of Hashes")
    end

    it "lets anything through when validation is off, still expanding known paths" do
      expect(build(scatter, {markr: 1, marker_color: "red"}, validate: false))
        .to eq("markr" => 1, "marker" => {"color" => "red"})
    end
  end
end
