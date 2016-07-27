module Octo
  module Search
    module Searchable

      # Extend the class with callbacks for indexing the document or deleting
      #   it based on appropriate events
      #
      def self.included(base)
        [:save, :create, :update].each do |mtd|
          base.send("after_#{ mtd }", lambda { async_index indexed_json })
        end
        base.after_destroy { async_delete id }
      end

      # Perform an async indexing of the data
      # @param [Hash] data The data to be indexed
      def async_index(data)
        _data = { index: index_name,
                  body: data }
        Resque.enqueue(Octo::Search::Indexer, :index, _data)
      end

      # Perform async delete of the document from index.
      # @param [Fixnum] id The ID of the document to be removed from the index
      #
      def async_delete(id)
        Resque.enqueue(Octo::Search::Indexer, :delete, id)
      end

      # Helper module for getting the index name corresponding to the class
      # @return [String] The name of the index to be used in elasticsearch
      #
      def index_name
        @index_name ||= self.class.to_s.split(/::/).last.downcase
      end

    end
  end
end

