require 'spec_helper'

describe Plotly::Client do
  let(:username) { ENV['PLOTLY_USERNAME'] }
  let(:api_key)  { ENV['PLOTLY_API_KEY'] }
  let(:client)   { Plotly::Client.new(username, api_key) }

  it 'is instantiated' do
    expect(client).to be_a Plotly::Client
  end
end
