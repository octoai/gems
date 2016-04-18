require 'octocore/callbacks'
require 'octorecommender'
require 'resque'
require 'resque-scheduler'

module Octo
  module OctoHooks

    # Define the custom tasks that need to be done
    #   upon various hooks
    Octo::Callbacks.after_app_init lambda { |opts|
      update_scheduler opts
    }

    # Extend the methods here
    module ClassMethods

      # Updates the scheduler
      # @param [Hash] opts The options hash as passed
      def update_scheduler(opts)
        user = opts[:user]
        recommender = Octo::Recommender.new
        arr = recommender.recommended_time(user)
        arr.each do |r|
          Resque.enqueue_at(r, Octo::Schedulers, user)
        end
      end

    end

  end
end