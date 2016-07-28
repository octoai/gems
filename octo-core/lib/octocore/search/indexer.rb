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
      # @param [Hash] opts The data to be used while performing the action
      # @option opts [String] idx_name The index name to be used
      # @option opts [String] doc_type The document type of the document
      # @option opts [String] id The ID of the document
      # @option opts [Hash] body The body of the document to be indexed
      #
      def self.perform(action, opts={})
        action = action.to_sym
        if action == :index
          self.client.index index: opts['idx_name'],
            type: opts['doc_type'],
            id: opts['body']['id'],
            body: opts['body']
        elsif action == :delete
          self.client.delete index: opts['idx_name'],
            type: opts['doc_type'],
            id: opts['id']
        end
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
