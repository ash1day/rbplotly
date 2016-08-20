require 'spec_helper'

describe Plotly::Layout do
  let(:layout) { Plotly::Layout.new(params) }

  describe '#initialize' do
    context 'with no params' do
      let(:params) { Hash.new }
      it { expect(layout).to be_a Plotly::Layout }
    end

    context 'with params' do
      let(:params) { { barmode: 'stack' } }
      it { expect(layout).to be_a Plotly::Layout }
    end
  end
end
