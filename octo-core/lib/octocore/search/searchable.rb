require 'elasticsearch/model'

module Octo
  module Search
    module Searchable

      # Extend the class with callbacks for indexing the document or deleting
      #   it based on appropriate events
      #
      def self.included(base)
        base.send(:include, ::Elasticsearch::Model)
        [:save].each do |mtd|
          base.send("after_#{ mtd }", lambda { async_index self })
        end
        base.after_destroy { async_delete self }
      end

      # Perform an async indexing of the data
      # @param [Object] model The model instance to be indexed
      #
      def async_index(model)
        opts = {
          idx_name: model.__elasticsearch__.index_name,
          doc_type: model.__elasticsearch__.document_type,
          body: model.as_indexed_json
        }
        Resque.enqueue(Octo::Search::Indexer, :index, opts)
      end

      # Perform async delete of the document from index.
      # @param [Object] model The model instance to be indexed
      #
      def async_delete(model)
        opts = {
          idx_name: model.__elasticsearch__.index_name,
          doc_type: model.__elasticsearch__.document_type,
          id: model.id
        }
        Resque.enqueue(Octo::Search::Indexer, :delete, opts)
      end

    end
  end
end

