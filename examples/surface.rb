# A 3D surface you can rotate, with contours projected onto the floor.
require "rbplotly"

xs = (-30..30).map { |i| i / 10.0 }
ys = xs
z = ys.map { |y| xs.map { |x| 4 * Math.sin(x**2 + y**2) / (1 + x**2 + y**2) } }

fig = Plotly::Figure.new
  .add_surface(x: xs, y: ys, z: z, colorscale: "Viridis", contours_z: {show: true, usecolormap: true, project_z: true})
  .update_layout(title_text: "z = 4 sin(x² + y²) / (1 + x² + y²)", scene_camera_eye: {x: 1.6, y: 1.4, z: 0.9}, height: 600)

fig.write_html("surface.html", open: true) if __FILE__ == $PROGRAM_NAME
