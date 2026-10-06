# Response times of three services: histograms on top, box plots below, sharing the x axis.
require "rbplotly"

rng = Random.new(3)
lognormal = ->(mu, sigma) { Math.exp(mu + sigma * Math.sqrt(-2 * Math.log(1 - rng.rand)) * Math.cos(2 * Math::PI * rng.rand)) }
services = {"search" => [4.0, 0.35], "checkout" => [4.6, 0.25], "profile" => [3.6, 0.5]}
colors = {"search" => "#636efa", "checkout" => "#ef553b", "profile" => "#00cc96"}
samples = services.transform_values { |(mu, sigma)| Array.new(800) { lognormal.call(mu, sigma) } }

fig = Plotly.make_subplots(rows: 2, cols: 1, shared_xaxes: true, vertical_spacing: 0.05)
samples.each do |name, values|
  fig.add_histogram(x: values, name: name, legendgroup: name, marker_color: colors[name], opacity: 0.6, nbinsx: 60, row: 1, col: 1)
  fig.add_box(x: values, name: name, legendgroup: name, marker_color: colors[name], showlegend: false, boxpoints: false, row: 2, col: 1)
end
fig.update_layout(barmode: :overlay, title_text: "Response time (ms)")
fig.update_yaxes({domain: [0.3, 1.0]}, row: 1, col: 1)
fig.update_yaxes({domain: [0.0, 0.25]}, row: 2, col: 1)

fig.write_html("distributions.html", open: true) if __FILE__ == $PROGRAM_NAME
