require 'spec_helper'

describe Plotly::Layout do
  let(:layout) { Plotly::Layout.new(params) }
  let(:params) { { barmode: 'stack' } }

  describe '#initialize' do
    context 'with no params' do
      let(:params) { Hash.new }
      it { expect(layout).to be_a Plotly::Layout }
    end

    context 'with params' do
      it { expect(layout).to be_a Plotly::Layout }
    end
  end

  describe '#to_h' do
    it { expect(layout.to_h).to eq params }
  end
end
