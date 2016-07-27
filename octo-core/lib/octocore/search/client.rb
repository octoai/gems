require 'multi_json'
require 'faraday'
require 'elasticsearch/api'

module Octo

  # Search wrapper around ElasticSearch
  module Search

    class Client

      include Elasticsearch::API

      # Low level method for performing a request to Elastic Search cluster
      # @param [String] method The method ex: get, put, post, etc..
      # @param [String] path The path of the request
      # @param [Hash] params The params of the request
      # @param [String] body The body of the request
      def perform_request(method, path, params, body)
        Octo.logger.info "--> #{method.upcase} #{path} #{params} #{body}"

        response = connection.run_request \
          method.downcase.to_sym,
          path,
          ( body ? MultiJson.dump(body): nil ),
          {'Content-Type' => 'application/json'}

        Octo.logger.info "#{ response.status }, #{ response.body }"
      end

      # Creates a new connection to the server if not already done
      def connection
        unless @connection
          @connection = ::Faraday::Connection.new(url: Octo.get_config(:search)[:server])
        end
        @connection
      end

    end
  end
end

