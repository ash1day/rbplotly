# frozen_string_literal: true

RSpec.describe "Plotly.make_subplots" do
  it "lays out a grid of axes and places traces by row and column" do
    fig = Plotly.make_subplots(rows: 2, cols: 2, horizontal_spacing: 0.1, vertical_spacing: 0.2)
      .add_scatter(y: [1], row: 1, col: 1)
      .add_bar(y: [2], row: 2, col: 2)

    expect(fig.data.map { |t| [t["xaxis"], t["yaxis"]] }).to eq([%w[x y], %w[x4 y4]])
    expect(fig.layout["xaxis"]).to include("domain" => [0.0, 0.45], "anchor" => "y")
    expect(fig.layout["xaxis2"]).to include("domain" => [0.55, 1.0], "anchor" => "y2")
    expect(fig.layout["yaxis"]).to include("domain" => [0.6, 1.0], "anchor" => "x")
    expect(fig.layout["yaxis3"]).to include("domain" => [0.0, 0.4], "anchor" => "x3")
  end

  it "shares axes by linking them and hiding the repeated tick labels" do
    fig = Plotly.make_subplots(rows: 2, cols: 2, shared_xaxes: true, shared_yaxes: true)
    expect(fig.layout["xaxis"]).to include("matches" => "x3", "showticklabels" => false)
    expect(fig.layout["xaxis3"]).not_to include("matches")
    expect(fig.layout["yaxis2"]).to include("matches" => "y", "showticklabels" => false)
    expect(fig.layout["yaxis"]).not_to include("matches")
  end

  it "titles each subplot with an annotation above it" do
    fig = Plotly.make_subplots(cols: 2, subplot_titles: ["Left", "Right"], horizontal_spacing: 0.2)
    left, right = fig.layout["annotations"]
    expect(left).to include("text" => "Left", "x" => 0.2, "y" => 1.0, "xref" => "paper", "yanchor" => "bottom", "showarrow" => false)
    expect(right).to include("text" => "Right", "x" => 0.8)
  end

  it "updates the axes of one cell or of every cell" do
    fig = Plotly.make_subplots(rows: 1, cols: 2)
    fig.update_xaxes(title_text: "time")
    fig.update_yaxes({type: :log}, row: 1, col: 2)
    expect([fig.layout.dig("xaxis", "title"), fig.layout.dig("xaxis2", "title")]).to all(eq("text" => "time"))
    expect([fig.layout.dig("yaxis", "type"), fig.layout.dig("yaxis2", "type")]).to eq([nil, :log])
  end

  it "updates axes that traces refer to even when the layout does not define them yet" do
    fig = Plotly::Figure.new.add_scatter(y: [1]).add_scatter(y: [2], xaxis: "x2", yaxis: "y2")
    fig.update_xaxes(title_text: "time")
    expect(fig.layout.keys).to contain_exactly("xaxis", "xaxis2")
  end

  it "updates only the traces in a given cell" do
    fig = Plotly.make_subplots(rows: 1, cols: 2).add_scatter(y: [1], row: 1, col: 1).add_scatter(y: [2], row: 1, col: 2)
    fig.update_traces({name: "right"}, row: 1, col: 2)
    expect(fig.data.map { |t| t["name"] }).to eq([nil, "right"])
  end

  it "places domain traces such as pies in their cell and updates them by cell" do
    fig = Plotly.make_subplots(rows: 1, cols: 2).add_pie(values: [1], row: 1, col: 1).add_pie(values: [2], row: 1, col: 2)
    fig.update_traces({hole: 0.5}, row: 1, col: 2)
    expect(fig.data.map { |t| t["hole"] }).to eq([nil, 0.5])
  end

  it "leaves traces that are not on x/y axes or in a cell out of cell updates" do
    fig = Plotly.make_subplots(rows: 1, cols: 2)
      .add_scatter(y: [1], row: 1, col: 1)
      .add_surface(z: [[1, 2], [3, 4]])
      .add_scatter(y: [2], xaxis: :x2, yaxis: :y2)
    fig.update_traces({opacity: 0.5}, row: 1, col: 1)
    fig.update_traces({name: "right"}, row: 1, col: 2)
    expect(fig.data.map { |t| t["opacity"] }).to eq([0.5, nil, nil])
    expect(fig.data.map { |t| t["name"] }).to eq([nil, nil, "right"])
  end

  it "rejects a cell outside the grid and row/col on a figure without subplots" do
    fig = Plotly.make_subplots(rows: 1, cols: 2)
    expect { fig.add_scatter(y: [1], row: 2, col: 1) }.to raise_error(ArgumentError, "row 2, col 1 is outside the 1x2 subplot grid")
    expect { Plotly::Figure.new.add_scatter(y: [1], row: 1, col: 1) }.to raise_error(ArgumentError, /make_subplots/)
  end

  it "rejects more titles than cells" do
    expect { Plotly.make_subplots(cols: 2, subplot_titles: %w[a b c]) }.to raise_error(ArgumentError, /3 subplot titles for 2 cells/)
  end

  it "rejects invalid spacing before it can overlap or collapse cells" do
    [-0.1, Float::NAN, Float::INFINITY, "0.1", 1.1, false].each do |spacing|
      expect { Plotly.make_subplots(cols: 2, horizontal_spacing: spacing) }.to raise_error(ArgumentError, /horizontal_spacing/)
      expect { Plotly.make_subplots(rows: 2, vertical_spacing: spacing) }.to raise_error(ArgumentError, /vertical_spacing/)
    end
    expect { Plotly.make_subplots(cols: 3, horizontal_spacing: 0.5) }.to raise_error(ArgumentError, /no room/)
    expect { Plotly.make_subplots(rows: 0) }.to raise_error(ArgumentError, /positive integers/)
    expect { Plotly.make_subplots(cols: "2") }.to raise_error(ArgumentError, /positive integers/)
  end

  it "allocates relative widths and top-to-bottom heights after subtracting spacing" do
    fig = Plotly.make_subplots(rows: 2, cols: 2, column_widths: [1, 3], row_heights: [3, 1],
      horizontal_spacing: 0.2, vertical_spacing: 0.2, subplot_titles: %w[a b c d])
    expect(fig.layout.dig("xaxis", "domain")).to eq([0.0, 0.2])
    expect(fig.layout.dig("xaxis2", "domain")).to eq([0.4, 1.0])
    expect(fig.layout.dig("yaxis", "domain")).to eq([0.4, 1.0])
    expect(fig.layout.dig("yaxis3", "domain")).to eq([0.0, 0.2])
    expect(fig.layout["annotations"].map { |a| [a["x"], a["y"]] }).to eq([[0.1, 1.0], [0.7, 1.0], [0.1, 0.2], [0.7, 0.2]])
    fig.add_pie(values: [1, 2], row: 2, col: 2)
    expect(fig.data.first["domain"]).to eq("x" => [0.4, 1.0], "y" => [0.0, 0.2])
  end

  it "requires one positive finite weight per row or column" do
    [[1], [1, 0], [-1, 1], [1, Float::NAN], [1, Float::INFINITY], [1, "2"], "1,2", false].each do |weights|
      expect { Plotly.make_subplots(cols: 2, column_widths: weights) }.to raise_error(ArgumentError, /column_widths/)
      expect { Plotly.make_subplots(rows: 2, row_heights: weights) }.to raise_error(ArgumentError, /row_heights/)
    end
    fig = Plotly.make_subplots(cols: 2, column_widths: [1e308, 1e308], horizontal_spacing: 0)
    expect(fig.layout.dig("xaxis2", "domain")).to eq([0.5, 1.0])
  end

  it "adds independent right y axes without changing existing primary axis numbering" do
    fig = Plotly.make_subplots(cols: 2, specs: [[{secondary_y: true}, {secondary_y: true}]], shared_yaxes: true)
      .add_bar(y: [1], row: 1, col: 1)
      .add_scatter(y: [100], row: 1, col: 1, secondary_y: true)
      .add_scatter(y: [200], row: 1, col: 2, secondary_y: true)
    expect(fig.data.map { |t| [t["xaxis"], t["yaxis"]] }).to eq([%w[x y], %w[x y3], %w[x2 y4]])
    expect(fig.layout["yaxis3"]).to include("anchor" => "x", "overlaying" => "y", "side" => "right")
    expect(fig.layout["yaxis4"]).to include("anchor" => "x2", "overlaying" => "y2", "side" => "right")
    expect(fig.layout["yaxis2"]).to include("matches" => "y")
    expect(fig.layout["yaxis4"]).not_to have_key("matches")
  end

  it "filters primary and secondary traces and axes by cell or across the grid" do
    fig = Plotly.make_subplots(cols: 2, specs: [[{secondary_y: true}, {}]])
      .add_bar(y: [1], row: 1, col: 1)
      .add_scatter(y: [100], row: 1, col: 1, secondary_y: true)
      .add_bar(y: [2], row: 1, col: 2)
    fig.update_traces(name: "right", secondary_y: true)
    expect(fig.data.map { |t| t["name"] }).to eq([nil, "right", nil])
    fig.update_traces(opacity: 0.5, row: 1, col: 1)
    expect(fig.data.map { |t| t["opacity"] }).to eq([0.5, 0.5, nil])
    fig.update_traces(name: "left", row: 1, col: 1, secondary_y: false)
    expect(fig.data.map { |t| t["name"] }).to eq(["left", "right", nil])
    fig.update_yaxes(title_text: "Percent", secondary_y: true)
    expect(fig.layout.dig("yaxis3", "title", "text")).to eq("Percent")
    expect(fig.layout.dig("yaxis", "title")).to be_nil
    fig.update_yaxes(showgrid: false, row: 1, col: 1)
    expect(fig.layout.values_at("yaxis", "yaxis3").map { |a| a["showgrid"] }).to eq([false, false])
    expect(fig.layout["yaxis2"]).not_to have_key("showgrid")
    fig.update_yaxes(zeroline: false, secondary_y: false)
    expect(fig.layout["yaxis3"]).not_to have_key("zeroline")
  end

  it "rejects invalid secondary-axis specifications and placement without adding a trace" do
    [[], [[nil]], [[{type: "scene"}]], [[{secondary_y: "yes"}]]].each do |specs|
      expect { Plotly.make_subplots(specs: specs) }.to raise_error(ArgumentError)
    end
    fig = Plotly.make_subplots(cols: 2, specs: [[{"secondary_y" => true}, {}]])
    expect { fig.add_bar(y: [1], row: 1, col: 2, secondary_y: true) }.to raise_error(ArgumentError, /secondary_y/)
    expect { fig.add_pie(values: [1], row: 1, col: 1, secondary_y: true) }.to raise_error(ArgumentError, /cartesian/)
    expect { fig.add_bar(y: [1], secondary_y: true) }.to raise_error(ArgumentError, /outside/)
    expect { fig.add_bar(y: [1], secondary_y: "yes") }.to raise_error(ArgumentError, /secondary_y/)
    expect(fig.data).to eq([])
    expect { Plotly::Figure.new.update_yaxes(secondary_y: true) }.to raise_error(ArgumentError, /make_subplots/)
  end

  it "does not partially update a cell when a secondary trace rejects an attribute" do
    fig = Plotly.make_subplots(specs: [[{secondary_y: true}]])
      .add_bar(y: [1], row: 1, col: 1)
      .add_scatter(y: [100], row: 1, col: 1, secondary_y: true)
    before = fig.to_json
    expect { fig.update_traces(width: 0.5, row: 1, col: 1) }
      .to raise_error(Plotly::ValidationError, /data\[1\].width/)
    expect(fig.to_json).to eq(before)
    fig.update_traces(width: 0.5, row: 1, col: 1, secondary_y: false)
    expect(fig.data.map { |trace| trace["width"] }).to eq([0.5, nil])
  end
end
