require 'octocore/search/client'

module Octo
  module Search

    # Its a Resque worker that sends index calls
    #
    class Indexer

      # The queue on which the job shall be performed
      #
      @queue = :indexer_queue

      # Performs the indexing part
      # @param [String] action The action to be performed. Namely `index` or
      #   `delete`
      # @param [Hash] data The data to be used while performing the action
      #
      def self.perform(action, data)
        _data = data.deep_symbolize_keys
        indexname = _data.delete(:index)
        self.client.index index: indexname,
          type: indexname,
          id: _data[:body][:id],
          body: _data.delete(:body)
      end

      # Gets the search client for the indexer.
      # @return [Octo::Search::Client] A search client
      #
      def self.client
        @client ||= Octo::Search::Client.new
      end

    end
  end
end
