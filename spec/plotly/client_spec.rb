require 'spec_helper'

describe Plotly::Client do
  let(:username) { ENV['PLOTLY_USERNAME'] }
  let(:api_key)  { ENV['PLOTLY_API_KEY'] }
  let(:client)   { Plotly::Client.new(username: username, api_key: api_key) }

  it 'is instantiated' do
    expect(client).to be_a Plotly::Client
  end

  it 'plots image' do
    n = 100

    x  = (1...n).map { |i| i.to_f / n }
    y0 = (1...n).map { rand(-2.0...2.0) + 5 }
    y1 = (1...n).map { rand(-2.0...2.0) }
    y2 = (1...n).map { rand(-2.0...2.0) - 5 }

    trace0 = {
      x: x,
      y: y0,
      type: 'scatter',
      mode: 'markers'
    }

    trace1 = trace0.merge(y: y1, mode: 'markers+lines')
    trace2 = trace0.merge(y: y2, mode: 'lines')

    client.plot_image([trace0, trace1, trace2], 'tmp/plot.png', :png)
  end
end
