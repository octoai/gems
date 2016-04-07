require 'predictor'
require 'octorecommender/recommenders/product_recommender'
require 'octorecommender/recommenders/time_recommender'


module Octo
  class Recommender

    TIME_HHMM = '%H%M'

    # Initializes the Recommender.
    def initialize
      @product_recommenders = {}
      @time_recommenders = {}

      # This option chosen as ruby seems to take a LOOOOOOOOOOT of time
      # in processing.
      Octo::Recommenders::ProductRecommender.processing_technique(:union)
      Octo::Recommenders::ProductRecommender.processing_technique :union

      Octo::Enterprise.each do |enterprise|
        @product_recommenders[enterprise.id] = Octo::Recommenders::ProductRecommender.new(enterprise.id)
        @time_recommenders[enterprise.id] = Octo::Recommenders::TimeRecommender.new(enterprise.id)
      end
    end

    # Register a user, product view relation.
    # @param [Octo::User] user The user object
    # @param [Octo::Product] product The product object
    def register_user_product_view(user, product)
      @product_recommenders[user.enterprise_id].add_to_matrix(:users,
          user.id,
          product.id
      )

      register_product product
    end

    # Register a Product for recommendation
    # @param [Octo::Product] product The product object
    def register_product(product)
      eid = product.enterprise_id
      product.categories.each do |cat_text|
        @product_recommenders[eid].add_to_matrix(:categories,
            cat_text,
            product.id
        )
      end
      product.tags.each do |tag_text|
        @product_recommenders[eid].add_to_matrix(:tags,
            tag_text,
            product.id
        )
      end
    end

    # Register a user, action-time view relation.
    # @param [Octo::User] user The user object
    # @param [Time] ts The time at which user takes some action
    def register_user_action_time(user, ts = Time.now.floor)
      eid = user.enterprise_id
      @time_recommenders[eid].add_to_matrix(:users,
          user.id,
          ts.to_i
      )

      @time_recommenders[eid].add_to_matrix(:hourminutes,
          ts.strftime(TIME_HHMM),
          ts.to_i
      )

      @time_recommenders[eid].add_to_matrix(:days,
          ts.strftime('%A'),
          ts.to_i
      )
    end

    # Get recommended products for a user
    # @param [Octo::User] user The user object for whom product
    #   recommendations to be fetched
    # @return [Array<Octo::Product>] An array of Octo::Product recommended
    def recommended_products(user)
      eid = user.enterprise_id
      recommendations = @product_recommenders[eid].predictions_for(
          user.id,
          matrix_label: :users
      )
      recommendations.collect do |x|
        args = { enterprise_id: eid, id: x.to_i}
        Octo::Product.get_cached(args)
      end
    end

    # Get recommended time for a user
    # @param [Octo::User] user The user for whom time to be fetched
    # @return [Array<Time>] The array of time recommended
    def recommended_time(user)
      eid = user.enterprise_id
      recommendations = @time_recommenders[eid].predictions_for(user.id, matrix_label: :users)
      recommendations.map do |ts|
        convert_to_future(Time.at(ts.to_i))
      end
    end

    # Creates a delayed job to process all the recommenders for all the
    #   enterprises or can provide specific options as well
    def process!(opts = {})
      @product_recommenders.values.each do |recomm|
        recomm.process!
      end
      @time_recommenders.values.each do |recomm|
        recomm.process!
      end
    end

    # Converts a time from past to a similar time in future.
    #   This is necessary as CF would return one of the dates
    #   from past. We need sometime from future.
    def convert_to_future(ts)
      ts + (Time.now.beginning_of_day - ts.beginning_of_day) + 7.day
    end

  end
end