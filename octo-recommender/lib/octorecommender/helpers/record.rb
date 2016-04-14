# Overriding Product class so as to add
#   recommender related helper methods
module Octo
  module Record

    def similarities(opts={})
      eid = self.enterprise.id
      recommender.similar_products self, opts
    end

    private

    # Generate the recommender instance
    # @return [Octo::Recommender]
    def recommender
      @recommender = Octo::Recommender.new unless @recommender
      @recommender
    end
  end
end