# A moving point with named frames and a replay button.
# frozen_string_literal: true

require "rbplotly"

fig = Plotly::Figure.new.add_scatter(x: [0], y: [0], mode: :markers, marker_size: 18)
fig.update_layout(title_text: "A moving point", xaxis_range: [-0.5, 4.5], yaxis_range: [-0.5, 4.5],
  updatemenus: [{type: :buttons, buttons: [{label: "Replay", method: :animate,
                                            args: [nil, {mode: "immediate", fromcurrent: false, frame: {duration: 600}, transition: {duration: 300}}]}]}])
[0, 1, 4, 2, 3].each_with_index do |y, x|
  fig.add_frame(name: "step-#{x}", data: [{x: [x], y: [y]}])
end

fig.write_html("animation.html", open: true) if __FILE__ == $PROGRAM_NAME
