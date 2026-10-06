# Where a (made-up) engineering budget goes, as a sunburst you can click to zoom into.
require "rbplotly"

budget = {
  "Product" => {"Web" => 420, "Mobile" => 310, "Design" => 140},
  "Platform" => {"Infrastructure" => 380, "Data" => 260, "Security" => 120},
  "Operations" => {"Support" => 180, "Tooling" => 90}
}

ids = []
labels = []
parents = []
values = []
budget.each do |group, teams|
  ids << group
  labels << group
  parents << ""
  values << teams.values.sum
  teams.each do |team, amount|
    ids << "#{group}/#{team}"
    labels << team
    parents << group
    values << amount
  end
end

fig = Plotly::Figure.new
  .add_sunburst(ids: ids, labels: labels, parents: parents, values: values, branchvalues: :total,
    hovertemplate: "%{label}: $%{value}k<extra></extra>")
  .update_layout(title_text: "Engineering budget (USD thousand)", margin: {t: 60, l: 10, r: 10, b: 10})

fig.write_html("sunburst.html", open: true) if __FILE__ == $PROGRAM_NAME
