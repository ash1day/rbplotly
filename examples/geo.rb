# Cities on a world map. No map token is needed: plotly.js draws its own outlines.
require "rbplotly"

cities = {
  "Tokyo" => [35.68, 139.69, 37.4], "Delhi" => [28.61, 77.21, 32.9], "Shanghai" => [31.23, 121.47, 29.2],
  "São Paulo" => [-23.55, -46.63, 22.6], "Mexico City" => [19.43, -99.13, 22.3], "Cairo" => [30.04, 31.24, 21.8],
  "New York" => [40.71, -74.01, 18.9], "Lagos" => [6.52, 3.38, 15.9], "London" => [51.51, -0.13, 9.6]
}

fig = Plotly::Figure.new
  .add_scattergeo(
    lat: cities.values.map { |c| c[0] }, lon: cities.values.map { |c| c[1] }, text: cities.keys,
    marker: {size: cities.values.map { |c| c[2] }, sizemode: :area, sizeref: 0.02, color: "crimson", opacity: 0.7},
    hovertemplate: "%{text}: %{marker.size}M<extra></extra>"
  )
  .update_layout(title_text: "Metropolitan population (millions)", geo: {projection_type: "natural earth", showland: true, landcolor: "#eceff1"})

fig.write_html("geo.html", open: true) if __FILE__ == $PROGRAM_NAME
