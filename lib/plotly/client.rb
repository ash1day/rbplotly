require 'faraday'
require 'base64'
require 'json'

module Plotly
  class Client
    # @param username [String]
    # @param api_key [String]
    def initialize(username: nil, api_key: nil)
      @conn = Faraday.new(
        url: 'https://api.plot.ly/v2',
        headers: build_headers(username, api_key)
      )
    end

    # @param data [Array]
    # @param image_path [String]
    # @param image_type [String]
    # @param layout [Hash]
    def plot_image(data, image_path, image_type, layout = {})
      payload = {
        figure: {
          data: data,
          layout: layout
        },
        format: image_type
      }.to_json

      res = @conn.post('images', payload)
      IO.binwrite(image_path.to_s, res.body)
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
