# Where visitors go after landing: a Sankey diagram of page flows.
require "rbplotly"

pages = ["Landing", "Docs", "Pricing", "Sign up", "Left"]
flows = [
  ["Landing", "Docs", 420], ["Landing", "Pricing", 310], ["Landing", "Left", 270],
  ["Docs", "Sign up", 160], ["Docs", "Left", 260], ["Pricing", "Sign up", 190], ["Pricing", "Left", 120]
]

fig = Plotly::Figure.new
  .add_sankey(
    node: {label: pages, pad: 20, thickness: 18},
    link: {
      source: flows.map { |from, _, _| pages.index(from) },
      target: flows.map { |_, to, _| pages.index(to) },
      value: flows.map(&:last)
    }
  )
  .update_layout(title_text: "Visitor flow")

fig.write_html("sankey.html", open: true) if __FILE__ == $PROGRAM_NAME
