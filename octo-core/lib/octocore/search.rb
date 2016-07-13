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

    # Setup module for ElasticSearch
    module Setup

      # Creates the necessary indices
      class Create

        def self.perform
          sclient = Octo::Search::Client.new
          sconfig = Octo.get_config(:search)

          # Check if any indices specified exists. If not exists, create them
          sconfig[:index].keys.each do |index_name|
            args = { index: index_name }
            if sclient.indices.exists?(args)
              Octo.logger.info "Search Index: #{ index_name } exists."
            else
              Octo.logger.warn "Search Index: #{ index_name } DOES NOT EXIST."
              Octo.logger.info "Creating Index: #{ index_name }"
              create_args = {
                index: index_name,
                body: sconfig[:index][index_name]
              }
              sclient.indices.create create_args
            end
          end

          # Also check if there are any indices present that should not be
          # present
          _indices = JSON.parse(sclient.cluster.state)['metadata']['indices'].
            keys.map(&:to_sym)
          extra_indices = _indices - sconfig[:index].keys
          Octo.logger.warn "Found extra indices: #{ extra_indices }"
        end
      end

      # Updates the indices.
      #   The major differene between this and the Create is that while create
      #   just checks for the existance by name, and passes if the name is found
      #   This actually overwrites all the mappings, properties, warmers etc
      #   So, this should be used only when we need to explicitly "UPDATE" the
      #   index.
      class Update

      end


    end


  end
end

