require 'octocore/callbacks'

module Octo

  module OctoHooks

    # Define the custom tasks that need to be done
    #   upon various hooks
    Octo::Callbacks.after_productpage_view lambda { |opts|
      update_recommenders opts
    }

    # Extend the methods here
    module ClassMethods

      # Updates the recommenders
      # @param [Hash] opts The options hash as passed
      def update_recommenders(opts)
        user = opts[:user]
        product = opts[:product]

        if user and product
          recommender = Octo::Recommender.new
          recommender.register_user_product_view(user, product)
          recommender.register_user_action_time(user, Time.now.floor)
        end
      end

    end
  end
end