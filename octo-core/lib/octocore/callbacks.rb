require 'hooks'
require 'active_support/concern'

module Octo

  # Central Hooks Module
  module OctoHooks

    extend ActiveSupport::Concern

    included do

      define_hooks :after_app_init, :after_app_login, :after_app_logout,
                   :after_page_view, :after_productpage_view

      # Define the after_app_init hook
      after_app_init do |args|
        update_counters args
      end

      # Define the after_app_login hook
      after_app_login do |args|
        update_counters args
      end

      # Define the after_app_logout hook
      after_app_logout do |args|
        update_counters args
      end

      # Define the after_page_view hook
      after_page_view do |args|
        update_counters args
      end

      # Define the after_productpage_view hook
      after_productpage_view do |args|
        Octo.logger.info 'productpage_view callback'
        update_counters args
      end
    end

    # Add all the post-hook-call methods here. Also, extend the module
    #   from here.
    module ClassMethods

      # Updates the counters of various types depending
      #   on the event.
      # @param [Hash] opts The options hash
      def update_counters(opts)
        if opts.has_key?(:product)
          Octo::ProductHit.increment_for(opts[:product])
        end
        if opts.has_key?(:categories)
          opts[:categories].each do |cat|
            Octo::CategoryHit.increment_for(cat)
          end
        end
        if opts.has_key?(:tags)
          opts[:tags].each do |tag|
            Octo::TagHit.increment_for(tag)
          end
        end
        if opts.has_key?(:event)
          Octo::ApiHit.increment_for(opts[:event])
        end
      end
    end

  end

  # The class responsible for handling callbacks.
  #   You must never need to make changes here
  class Callbacks
    include Hooks
    include Octo::OctoHooks

  end
end