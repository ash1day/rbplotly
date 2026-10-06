# Revenue by region, stacked per quarter, with totals in the hover label.
require "rbplotly"

quarters = %w[Q1 Q2 Q3 Q4]
revenue = {
  "Americas" => [42, 48, 51, 63],
  "Europe" => [31, 29, 35, 40],
  "Asia Pacific" => [18, 24, 30, 38]
}

fig = Plotly::Figure.new(layout: {barmode: :stack, title_text: "Revenue by region (USD million)"})
revenue.each do |region, values|
  fig.add_bar(x: quarters, y: values, name: region, hovertemplate: "%{x}: $%{y}M<extra>#{region}</extra>")
end
fig.update_layout(yaxis_tickprefix: "$", yaxis_ticksuffix: "M")

fig.write_html("bar.html", open: true) if __FILE__ == $PROGRAM_NAME
