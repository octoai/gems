module Octo
  module Searchable

    # Gets the search client
    def searchclient
      unless @searchClient
        @searchClient = Octo::Search::Client.new
      end
      @searchClient
    end

    # Defines the indice with which this would be indexed
    def indexable_with(indice_name, type)

    end

  end
end
