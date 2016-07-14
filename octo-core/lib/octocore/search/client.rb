require 'multi_json'
require 'faraday'
require 'elasticsearch/api'

module Octo

  # Search wrapper around ElasticSearch
  module Search

    class Client

      include Elasticsearch::API

      CONNECTION = ::Faraday::Connection.new(url: Octo.get_config(:search)[:server])

      # Low level method for performing a request to Elastic Search cluster
      # @param [String] method The method ex: get, put, post, etc..
      # @param [String] path The path of the request
      # @param [Hash] params The params of the request
      # @param [String] body The body of the request
      def perform_request(method, path, params, body)
        Octo.logger.debug "--> #{method.upcase} #{path} #{params} #{body}"

        CONNECTION.run_request \
          method.downcase.to_sym,
          path,
          ( body ? MultiJson.dump(body): nil ),
          {'Content-Type' => 'application/json'}
      end
    end
  end
end

