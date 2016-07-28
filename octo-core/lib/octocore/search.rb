require 'elasticsearch/model'

require 'octocore/search/client'
require 'octocore/search/indexer'
require 'octocore/search/searchable'

module Octo

  module Search

    class InitConnection

      # Connects to the elasticsearch cluster and validates the presence
      #   of indexes for all the classes which have included
      #   `Octo::Search::Searchable`
      #
      def self.connect
        if Octo.get_config(:search) and Octo.get_config(:search)[:server]
          Elasticsearch::Model.client = Octo::Search::Client.new

          klasses = ObjectSpace.each_object(Class).select do |c|
            c.included_modules.include? Octo::Search::Searchable
          end
          klasses.each { |k| k.__elasticsearch__.create_index! }
        end
      end

    end
  end
end

# Perform connection to Elasticsearch when required
#
Octo::Search::InitConnection.connect

