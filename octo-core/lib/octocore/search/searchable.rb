module Octo
  module Search
    module Searchable

      def self.included(base)
        [:save, :create, :update].each do |mtd|
          base.send("after_#{ mtd }", lambda { async_index indexed_json })
        end
        base.after_destroy { async_delete id }
      end

      def async_index(data)
        _data = { index: index_name,
                  body: data }
        Resque.enqueue(Octo::Search::Indexer, :index, _data)
      end

      def async_delete(id)
        Resque.enqueue(Octo::Search::Indexer, :delete, id)
      end

      def index_name
        @index_name ||= self.class.to_s.split(/::/).last.downcase
      end

    end
  end
end

