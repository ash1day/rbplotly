require "faraday"
require "base64"
require "json"

module Plotly
  class Client
    attr_reader :conn

    # @param username [String]
    # @param api_key [String]
    def initialize(username, api_key)
      @conn = Faraday.new(
        url: "https://api.plot.ly/v2",
        headers: build_headers(username, api_key),
      )
    end

    private

    # @param username [String]
    # @param api_key [String]
    # @return [Hash] HTTP headers
    def build_headers(username, api_key)
      encoded_auth = Base64.encode64("#{username}:#{api_key}")
      {
        "plotly-client-platform" => "Ruby #{Plotly::VERSION}",
        "content-type" => "application/json",
        authorization: "Basic #{encoded_auth}",
      }
    end
  end

  class << self
    # Set the default client which is automatically used when any clients aren't assigned.
    def auth(username, api_key)
      @client = Client.new(username, api_key)
    end

    # Set the default client
    def default_auth()
      #      @client = @client || Client.new(ENV['PLOTLY_USERNAME'], ENV['PLOTLY_API_KEY'])
      default_path = File.join(ENV["HOME"], ".plotly", ".credentials")
      credentials = JSON.load(File.read(default_path))
      @client = Client.new(credentials["username"], credentials["api_key"])
      #      @client = Client.new(username, api_key)
    end

    # Set the credentials for a specific client
    def set_credentials_file(username, api_key,
                             opts = { proxy_username: "",
                                      proxy_password: "",
                                      stream_ids: [] })
      credentials = {
        "username" => username,
        "api_key" => api_key,
        "proxy_username": opts[:proxy_username],
        "proxy_password": opts[:proxy_password],
        "stream_ids": opts[:stream_ids],
      }
      File.open(File.join(ENV["HOME"], ".plotly", ".credentials"), "w") do |f|
        f.write(JSON.pretty_generate(credentials))
      end
    end

    # @return [Plotly::Client]
    # @raise [RuntimeError]
    def client
      @client ? @client : raise("Authentication required")
    end
  end
end
