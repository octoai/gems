require 'predictor'
require 'octorecommender'

module Octo
  module Recommenders
    # The product recommender class. This class is responsible for recommending
    #   a (user, product)
    class ProductRecommender
      include Predictor::Base

      def initialize(prefix)
        @prefix = prefix
      end

      def get_redis_prefix
        @prefix
      end

      limit_similarities_to 20

      # Stores the user and product relation
      input_matrix :users, weight: 3.0

      # Store the relation between products asserted by their tags
      input_matrix :tags, weight: 2.0

      # Store the relation between products asserted by their
      #   categories
      input_matrix :categories, weight: 1.0
    end
  end
end