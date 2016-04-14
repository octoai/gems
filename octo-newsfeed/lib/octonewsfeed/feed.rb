require 'octorecommender'
require 'octonewsfeed/weaver'

module Octo
  module NewsFeed

    module Feed
      include Octo::NewsFeed::Weaver

      # Generate the newsfeed for a user. Optionally,
      #   specify a time so that things relevant at that time would show
      # @param [Octo::User] user The user for whom feed is to be generated
      # @param [Hash] opts The options to use for for generating feed
      def feed_for(user, opts = {})
        feed_products = {
            recommended: recommender.recommended_products(user),
            trending: trending_prods(user.enterprise),
            similar: similar_prods_user(user)
        }
        weave(feed_products)
      end

      private

      # Generate the recommender instance
      # @return [Octo::Recommender]
      def recommender
        @recommender = Octo::Recommender.new unless @recommender
        @recommender
      end

      # Gets the set of trending products for the enterprise. This is as per
      #   custom logic of how many trending products and of what type do we
      #   want to show to the user in his newsfeed.
      # @param [Octo::Enterprise] enterprise The enterprise for whom trendings
      #   to be calculated
      # @return [Array<Octo::Product>] An array of products
      def trending_prods(enterprise)
        eid = enterprise.id
        trending_now = Octo::ProductTrend.get_trending eid, Octo::Counter::TYPE_MINUTE, limit: 10
        trending_past = Octo::ProductTrend.get_trending eid, Octo::Counter::TYPE_HOUR, limit: 10
        trending_now.concat trending_past
      end

      # Finds the products similar to the ones that the user has seen before.
      # @param [Octo::User] user The user for whom similar products have to be
      #   found
      # @return [Array<Octo::Product>] An array of products
      def similar_prods_user(user, opts={})
        args = {
            enterprise_id: user.enterprise.id,
            userid: user.id
        }
        last_ppvs = Octo::ProductPageView.where(args).limit(opts.fetch(:limit, 10))
        last_seen_products = last_ppvs.collect do |ppv|
          Octo::Product.get_cached({ enterprise_id: user.enterprise.id,
                                     id: ppv.product_id})
        end
        similar_prods last_seen_products
      end

      # Get similar products for a set of products.
      # @param [Array<Octo::Product>] products An array of products for whom
      #   similarities have to be found
      # @return [Hash<Octo::Product => Array<Octo::Product>] Hash containing similar
      #   products array as value for product as key
      def similar_prods(products, opts={})
        products.inject({}) do |r,e|
          r[e] = e.similarities(opts)
          r
        end
      end

    end
  end
end