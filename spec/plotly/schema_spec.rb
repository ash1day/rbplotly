# frozen_string_literal: true

RSpec.describe Plotly::Schema do
  subject(:schema) { described_class.default }

  it "is built from the pinned plotly.js release" do
    expect(schema.plotly_js_version).to eq(Plotly::PLOTLY_JS_VERSION)
  end

  it "lists every trace type of that release" do
    expect(schema.trace_types).to include("scatter", "bar", "heatmap", "sankey", "scattermap")
  end

  it "describes nested attributes of a trace" do
    color = schema.trace("scatter").child("marker").child("color")
    expect(color).to be_leaf
    expect(color.type).to eq("color")
    expect(color.array_ok?).to be(true)
  end

  it "returns nil for unknown attributes and trace types" do
    expect(schema.trace("scatter").child("markr")).to be_nil
    expect(schema.trace("scatterr")).to be_nil
  end

  it "accepts numbered subplot ids such as xaxis2 or scene3 in the layout" do
    expect(schema.layout.child("xaxis2")).to be_object
    expect(schema.layout.child("scene3")).to be_object
    expect(schema.layout.child("xaxis1")).to be_nil
    expect(schema.layout.child("width2")).to be_nil
  end

  it "includes layout attributes that trace modules contribute" do
    expect(schema.layout.child("barmode").values).to include("stack", "group")
  end

  it "puts layout attributes of polar traces under the polar subplot" do
    expect(schema.layout.child("polar").child("barmode").values).to include("stack", "overlay")
    expect(schema.layout.child("polar2").child("bargap")).to be_leaf
  end

  it "describes arrays of objects such as annotations" do
    annotations = schema.layout.child("annotations")
    expect(annotations).to be_array
    expect(annotations.item.child("showarrow").type).to eq("boolean")
  end

  it "describes the metadata of animation frames" do
    expect(schema.frame.attribute_names).to contain_exactly("name", "group", "baseframe", "data", "layout", "traces")
  end
end
