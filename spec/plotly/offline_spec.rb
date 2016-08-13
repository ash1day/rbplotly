require 'spec_helper'

describe Plotly::Offline do
  it 'plots image' do
    n = 100

    x  = (0..n).map { |i| i.to_f / n }
    y0 = (0..n).map { rand(-2.0..2.0) + 5 }
    y1 = (0..n).map { rand(-2.0..2.0) }
    y2 = (0..n).map { rand(-2.0..2.0) - 5 }

    trace0 = {
      x: x,
      y: y0,
      type: 'scatter',
      mode: 'markers'
    }

    trace1 = trace0.merge(y: y1, mode: 'markers+lines')
    trace2 = trace0.merge(y: y2, mode: 'lines')

    Plotly::Offline.plot([trace0, trace1, trace2], path: 'tmp/plot.html', open: false)
  end
end
