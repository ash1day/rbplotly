require 'spec_helper'

describe 'Examples' do
  let(:path) { TMP_DIR + 'plot.html' }

  it 'Line chart example' do
    require 'rbplotly'

    x = [0, 1, 2, 3, 4]
    trace0 = { x: x, y: [0, 2, 1, 4, 3], type: :scatter, mode: :lines }
    trace1 = { x: x, y: [4, 1, 3, 0, 2], type: :scatter, mode: 'markers+lines' }
    data = [trace0, trace1] # data must be Array

    layout = { width: 500, height: 500 }

    plot = Plotly::Plot.new(data: data, layout: layout)

    plot.layout.height = 300 # You can change plot's attributes.

    plot.generate_html(path: path, open: false)
  end

  it 'Heatmap example' do
    data = [{
      x: %w(x1 x2 x3 x4 x5),
      y: %w(y1 y2 y3 y4 y5),
      z: (1..5).map { (1..5).map { rand(-5.0..5.0) } },
      type: :heatmap,
      colorscale: [
        [1.0, 'rgb(33, 150, 243)'],
        [0.0, 'rgb(256, 256, 256)']
      ]
    }]

    layout = { width: 500, height: 500 }

    plot = Plotly::Plot.new(data: data, layout: layout)
    plot.generate_html(path: path, open: false)
  end
end
