require 'spec_helper'

describe Plotly::Plot do
  let(:data) do
    n = 100

    x  = (1...n).map { |i| i.to_f / n }
    y0 = (1...n).map { rand(-2.0...2.0) + 5 }
    y1 = (1...n).map { rand(-2.0...2.0) }
    y2 = (1...n).map { rand(-2.0...2.0) - 5 }

    trace0 = { x: x, y: y0, type: 'scatter', mode: 'markers' }
    trace1 = trace0.merge(y: y1, mode: 'markers+lines')
    trace2 = trace0.merge(y: y2, mode: 'lines')

    [trace0, trace1, trace2]
  end

  let(:plot) { Plotly::Plot.new(data: data) }

  it 'can be instantiated' do
    expect(plot).to be_a Plotly::Plot
  end

  describe '#layout=' do
    it 'sets layout' do
      plot.layout = { xaxis: { title: 'x_title' } }
    end
  end

  describe '#generate_html' do
    it 'generates html which includes plotly.js' do
      path = TMP_DIR + 'scatter_and_line.html'
      plot.generate_html(path: path, open: false)
      generated_html = open(path).read
      expect(generated_html).to include('plotly.js')
    end
  end

#  describe '#download_image' do
#    let(:username) { ENV['PLOTLY_USERNAME'] }
#    let(:api_key)  { ENV['PLOTLY_API_KEY'] }
#    let(:path)     { TMP_DIR + 'scatter.png' }
#
#    context 'with instantiated client' do
#      let(:client) { Plotly::Client.new(username, api_key) }
#      it 'downloads image' do
#        plot.download_image(path: path, client: client)
#
#        generated_image = open(path).read
#        expect(generated_image).not_to include('errors')
#      end
#    end
#
#    context 'with no client' do
#      it 'raises error' do
#        expect { plot.download_image(path: path) }.to raise_error(RuntimeError)
#      end
#    end
#
#    context 'with default client' do
#      it 'downloads image' do
#        Plotly.auth(username, api_key)
#        plot.download_image(path: path, height: 300, width: 500, scale: 1)
#
#        generated_image = open(path).read
#        expect(generated_image).not_to include('errors')
#      end
#    end
#  end
end
