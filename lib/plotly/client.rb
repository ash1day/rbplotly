require 'faraday'
require 'base64'
require 'json'

module Plotly
  class Client
    attr_reader :conn

    # @param username [String]
    # @param api_key [String]
    def initialize(username, api_key)
      @conn = Faraday.new(
        url: 'https://api.plot.ly/v2',
        headers: build_headers(username, api_key)
      )
    end

    private

    # @param username [String]
    # @param api_key [String]
    # @return [Hash] HTTP headers
    def build_headers(username, api_key)
      encoded_auth = Base64.encode64("#{username}:#{api_key}")
      {
        'plotly-client-platform' => "Ruby #{Plotly::VERSION}",
        'content-type' => 'application/json',
        authorization: "Basic #{encoded_auth}"
      }
    end
  end
end
