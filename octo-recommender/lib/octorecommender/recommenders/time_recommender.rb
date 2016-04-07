require 'predictor'
require 'octorecommender'

module Octo

  module Recommenders

    # The time recommender class. This class would be responsible for recommending
    #   the next set of time for a (user, action)
    class TimeRecommender
      include Predictor::Base

      def initialize(prefix)
        @prefix = prefix
      end

      def get_redis_prefix
        @prefix
      end

      limit_similarities_to 20

      # This matrix stores the user and their action
      input_matrix :users, weight: 1.0

      # This matrix stores the relation between times in terms of
      # HHMM.
      # Ex:
      #   11/3/2016 11:30 and 12/3/2016 11:30 have the same HHMM
      input_matrix :hourminutes, weight: 3.0

      # This matrix stores the relation between times in terms of
      # days.
      # Ex:
      #   4/4/2016 (Monday) and 11/4/2016 (Monday) have the same day
      input_matrix :days, weight: 2.0
    end

  end

end