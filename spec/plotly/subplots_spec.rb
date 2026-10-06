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

  it "updates only the traces in a given cell" do
    fig = Plotly.make_subplots(rows: 1, cols: 2).add_scatter(y: [1], row: 1, col: 1).add_scatter(y: [2], row: 1, col: 2)
    fig.update_traces({name: "right"}, row: 1, col: 2)
    expect(fig.data.map { |t| t["name"] }).to eq([nil, "right"])
  end

  it "rejects a cell outside the grid and row/col on a figure without subplots" do
    fig = Plotly.make_subplots(rows: 1, cols: 2)
    expect { fig.add_scatter(y: [1], row: 2, col: 1) }.to raise_error(ArgumentError, "row 2, col 1 is outside the 1x2 subplot grid")
    expect { Plotly::Figure.new.add_scatter(y: [1], row: 1, col: 1) }.to raise_error(ArgumentError, /make_subplots/)
  end

  it "rejects more titles than cells" do
    expect { Plotly.make_subplots(cols: 2, subplot_titles: %w[a b c]) }.to raise_error(ArgumentError, /3 subplot titles for 2 cells/)
  end
end
