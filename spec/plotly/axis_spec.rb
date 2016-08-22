require 'spec_helper'

describe Plotly::Axis do
  let(:axis) { Plotly::Axis.new(params) }
  let(:params) { { title: 'x_title' } }

  describe '#initialize' do
    context 'with no params' do
      let(:params) { Hash.new }
      it { expect(axis).to be_a Plotly::Axis }
    end

    context 'with params' do
      it { expect(axis).to be_a Plotly::Axis }
    end
  end

  describe '#to_h' do
    it { expect(axis.to_h).to eq params }
  end
end
