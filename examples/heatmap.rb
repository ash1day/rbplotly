# Commits by weekday and hour, as an annotated heatmap.
require "rbplotly"

rng = Random.new(11)
weekdays = %w[Mon Tue Wed Thu Fri Sat Sun]
hours = (0..23).map { |h| format("%02d:00", h) }
counts = weekdays.each_index.map do |d|
  hours.each_index.map do |h|
    base = (d < 5) ? 12 * Math.exp(-((h - 14)**2) / 18.0) : 3 * Math.exp(-((h - 16)**2) / 30.0)
    (base + rng.rand(0..2)).round
  end
end

fig = Plotly::Figure.new
  .add_heatmap(z: counts, x: hours, y: weekdays, colorscale: "Blues", reversescale: true, texttemplate: "%{z}", hoverongaps: false)
  .update_layout(title_text: "Commits by weekday and hour", yaxis_autorange: "reversed")

fig.write_html("heatmap.html", open: true) if __FILE__ == $PROGRAM_NAME
