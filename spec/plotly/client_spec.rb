require 'spec_helper'

describe Plotly::Client do
  let(:username) { ENV['PLOTLY_USERNAME'] }
  let(:api_key)  { ENV['PLOTLY_API_KEY'] }
  subject(:client) { Plotly::Client.new(username, api_key) }

  it 'can be instantiated' do
    should be_a Plotly::Client
  end
end
