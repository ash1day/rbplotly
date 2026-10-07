# Orders and conversion on independent scales, beside a smaller product-mix panel.
# frozen_string_literal: true

require "rbplotly"

months = %w[Jan Feb Mar Apr May Jun]
fig = Plotly.make_subplots(cols: 2, column_widths: [2, 1], horizontal_spacing: 0.18,
  specs: [[{secondary_y: true}, {}]], subplot_titles: ["Orders and conversion", "Product mix"])
fig.add_bar(x: months, y: [100, 130, 170, 160, 210, 240], name: "Orders", row: 1, col: 1)
fig.add_scatter(x: months, y: [2.1, 2.4, 2.2, 2.9, 3.1, 3.4], name: "Conversion",
  mode: :"lines+markers", row: 1, col: 1, secondary_y: true)
fig.add_pie(labels: %w[Basic Pro Team], values: [50, 35, 15], hole: 0.5, row: 1, col: 2)
fig.update_yaxes(title_text: "Orders", secondary_y: false, row: 1, col: 1)
fig.update_yaxes(title_text: "Conversion", ticksuffix: "%", showgrid: false, secondary_y: true)
fig.update_layout(title_text: "Monthly performance", height: 480, legend_orientation: "h")

fig.write_html("secondary_axes.html", open: true) if __FILE__ == $PROGRAM_NAME
