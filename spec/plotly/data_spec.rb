require 'spec_helper'

describe Plotly::Data do
  let(:data) { Plotly::Data.new(params) }

  describe '#initialize' do
    context 'with no params' do
      let(:params) { Hash.new }
      it { expect(data).to be_a Plotly::Data }
    end

    context 'with params' do
      let(:params) do
        {
          x:    %w(giraffes orangutans monkeys),
          y:    [20, 14, 23],
          type: 'bar',
          name: 'SF Zoo'
        }
      end

      it { expect(data).to be_a Plotly::Data }
    end
  end

  describe '#to_h' do
    let(:params) { { x: Array.new(4, rand) } }
    it { expect(data.to_h).to eq params }
  end
end
