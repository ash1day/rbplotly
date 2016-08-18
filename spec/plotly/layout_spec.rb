require 'spec_helper'

describe Plotly::Layout do
  let(:layout) { Plotly::Layout.new }

  it 'can be instantiated' do
    expect(layout).to be_a Plotly::Layout
  end
end
