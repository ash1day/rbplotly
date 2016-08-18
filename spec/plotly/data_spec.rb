require 'spec_helper'

describe Plotly::Data do
  let(:data) { Plotly::Data.new }

  it 'can be instantiated' do
    expect(data).to be_a Plotly::Data
  end
end
