require 'faraday'
require 'faraday_middleware'

module Plotly
  class Client
    # @param username [String]
    # @param api_key [String]
    def initialize(username, api_key)
      @username = username
      @api_key = api_key
    end
  end
end
