# frozen_string_literal: true

RSpec.describe "Animation frames" do
  let(:fig) { Plotly::Figure.new.add_scatter(y: [0]).add_bar(y: [10]) }

  it "constructs and serializes frames without changing the JSON of static figures" do
    animated = Plotly::Figure.new(data: [{type: :bar, y: [1]}],
      frames: [{name: "next", data: [{y: [2]}], layout: {title_text: "Next"}}])
    expect(JSON.parse(animated.to_json)["frames"]).to eq([
      {"name" => "next", "data" => [{"y" => [2]}], "layout" => {"title" => {"text" => "Next"}}}
    ])
    expect(fig.to_h.keys).to eq(%w[data layout])
    restored = Plotly::Figure.new(**JSON.parse(animated.to_json).transform_keys(&:to_sym))
    expect(restored.to_json).to eq(animated.to_json)
  end

  it "infers trace types from the base data and respects explicit trace mappings" do
    expect(fig.add_frame(name: :step, traces: [1], data: [{marker_line_width: 2, orientation: :h}])).to equal(fig)
    expect(fig.frames.first["data"]).to eq([{"marker" => {"line" => {"width" => 2}}, "orientation" => :h}])
    # 'orientation' is shared, but 'width' belongs to bar and is not a scatter attribute.
    fig.add_frame(traces: [1], data: [{width: 0.5}])
    expect { fig.add_frame(traces: [0], data: [{width: 0.5}]) }.to raise_error(Plotly::ValidationError, /frames\[2\].data\[0\].width/)
    expect(fig.frames.size).to eq(2)
  end

  it "validates explicit trace types even without base data" do
    animated = Plotly::Figure.new(frames: [{data: [{type: :bar, width: 0.5}]}])
    expect(animated.frames.first["data"].first).to include("type" => "bar")
    expect { animated.add_frame(data: [{type: "scater"}]) }.to raise_error(Plotly::ValidationError, /trace type/)
  end

  it "reports nested attribute errors at the frame path" do
    expect { fig.add_frame(data: [{marker_size: -1}]) }.to raise_error(Plotly::ValidationError, /frames\[0\].data\[0\].marker.size/)
    expect { fig.add_frame(layout: {xaxis_title_typo: "x"}) }.to raise_error(Plotly::ValidationError, /frames\[0\].layout.xaxis.title.typo/)
    expect { fig.add_frame(namme: "x") }.to raise_error(Plotly::ValidationError, /frames\[0\].namme/)
  end

  it "rejects malformed frames and trace indices" do
    [nil, {}, false].each do |frames|
      expect { fig.frames = frames }.to raise_error(Plotly::ValidationError, /frames/)
    end
    [nil, [], "frame"].each do |frame|
      expect { fig.add_frame(frame) }.to raise_error(Plotly::ValidationError, /expected a Hash/)
    end
    [{data: {}}, {data: [1]}, {data: false}, {layout: []}, {layout: false},
      {traces: [-1]}, {traces: [1.5]}, {traces: "0"}, {traces: false}].each do |frame|
      expect { fig.add_frame(frame) }.to raise_error(Plotly::ValidationError)
    end
  end

  it "replaces frames atomically and allows clearing them" do
    fig.add_frame(name: "original", data: [{y: [1]}])
    expect { fig.frames = [{name: "new"}, {data: [{mode: "typo"}]}] }.to raise_error(Plotly::ValidationError)
    expect(fig.frames.map { |frame| frame["name"] }).to eq(["original"])
    fig.frames = []
    expect(fig.to_h).not_to have_key("frames")
  end

  it "preserves baseframe, group and layout-only frames" do
    fig.add_frame(name: "base", group: "series", layout: {xaxis_range: [0, 10]})
      .add_frame(name: "child", baseframe: "base", data: [{y: [3]}])
    expect(fig.frames.first).to include("group" => "series", "layout" => {"xaxis" => {"range" => [0, 10]}})
    expect(fig.frames.last["baseframe"]).to eq("base")
  end

  it "honors validate: false while normalizing known paths" do
    animated = Plotly::Figure.new(validate: false, frames: [{custom: true, data: [{marker_size: -1}], layout: {title_text: "x"}}])
    expect(animated.frames.first).to include("custom" => true, "data" => [{"marker" => {"size" => -1}}],
      "layout" => {"title" => {"text" => "x"}})
  end
end
