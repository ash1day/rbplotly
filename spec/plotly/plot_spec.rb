# frozen_string_literal: true

RSpec.describe Plotly::Plot do
  it "keeps 0.x code working while pointing to Plotly::Figure" do
    plot = nil
    expect {
      plot = described_class.new(data: [{x: [0, 1], y: [1, 0], type: :scatter, mode: :lines}], layout: {width: 500})
    }.to output(/Plotly::Plot is deprecated.*Plotly::Figure/).to_stderr

    expect(plot).to be_a(Plotly::Figure)
    expect(plot.layout).to eq("width" => 500)
  end

  it "maps generate_html to write_html" do
    plot = nil
    expect { plot = described_class.new(data: [{y: [1]}]) }.to output.to_stderr
    Dir.mktmpdir do |dir|
      path = File.join(dir, "old.html")
      expect(Plotly::Browser).to receive(:open).with(path)
      plot.generate_html(path: path)
      expect(File.read(path)).to include("Plotly.newPlot")
    end
  end
end
