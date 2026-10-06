# A small dashboard: four kinds of chart in one figure.
require "rbplotly"

months = %w[Jan Feb Mar Apr May Jun]
fig = Plotly.make_subplots(
  rows: 2, cols: 2,
  subplot_titles: ["Signups", "Conversion", "Plan mix", "Churn"],
  horizontal_spacing: 0.12, vertical_spacing: 0.2
)
fig.add_bar(x: months, y: [120, 150, 170, 160, 210, 240], name: "Signups", row: 1, col: 1)
fig.add_scatter(x: months, y: [2.1, 2.4, 2.2, 2.9, 3.1, 3.4], mode: :"lines+markers", name: "Conversion %", row: 1, col: 2)
fig.add_pie(labels: %w[Free Pro Team], values: [62, 28, 10], hole: 0.5, name: "Plans", row: 2, col: 1)
fig.add_scatter(x: months, y: [5.2, 4.8, 4.9, 4.1, 3.8, 3.5], fill: :tozeroy, name: "Churn %", row: 2, col: 2)
fig.update_layout(title_text: "Product metrics", showlegend: false, height: 620)
fig.update_yaxes({ticksuffix: "%"}, row: 1, col: 2)
fig.update_yaxes({ticksuffix: "%", rangemode: :tozero}, row: 2, col: 2)

fig.write_html("subplots.html", open: true) if __FILE__ == $PROGRAM_NAME
