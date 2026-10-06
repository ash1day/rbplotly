# Two clusters of points, colored by a third value on a continuous scale.
require "rbplotly"

rng = Random.new(7)
gaussian = -> { Math.sqrt(-2 * Math.log(1 - rng.rand)) * Math.cos(2 * Math::PI * rng.rand) }
points = 400.times.map do |i|
  cx, cy = i.even? ? [2.0, 3.0] : [5.0, 1.5]
  [cx + gaussian.call, cy + gaussian.call * 0.7]
end
x = points.map(&:first)
y = points.map(&:last)

fig = Plotly::Figure.new
  .add_scatter(
    x: x, y: y, mode: :markers,
    marker: {color: x.zip(y).map { |a, b| a * b }, colorscale: "Viridis", showscale: true, size: 8, opacity: 0.8},
    marker_colorbar_title_text: "x × y",
    hovertemplate: "x=%{x:.2f}<br>y=%{y:.2f}<extra></extra>"
  )
  .update_layout(title_text: "Clusters", xaxis_title_text: "x", yaxis_title_text: "y")

fig.write_html("scatter.html", open: true) if __FILE__ == $PROGRAM_NAME
