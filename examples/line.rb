# Daily active users over two quarters, with a 7-day moving average.
require "date"
require "rbplotly"

rng = Random.new(1)
days = (Date.new(2026, 1, 1)..Date.new(2026, 6, 30)).to_a
users = days.each_with_index.map { |day, i| 1200 + 4 * i + 300 * Math.sin(i / 9.0) + ((day.saturday? || day.sunday?) ? -250 : 0) + rng.rand(-60..60) }
average = users.each_index.map { |i| users[[0, i - 6].max..i].sum / (i - [0, i - 6].max + 1) }

fig = Plotly::Figure.new
  .add_scatter(x: days, y: users, mode: :lines, name: "Daily", line_color: "rgba(99, 110, 250, 0.35)")
  .add_scatter(x: days, y: average, mode: :lines, name: "7-day average", line_width: 3)
  .update_layout(
    title_text: "Daily active users",
    hovermode: "x unified",
    yaxis_title_text: "Users",
    legend: {orientation: "h", y: -0.15}
  )

fig.write_html("line.html", open: true) if __FILE__ == $PROGRAM_NAME
