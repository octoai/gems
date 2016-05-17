require 'set'
require 'active_support/concern'
require 'octocore/helpers/api_consumer_helper'

module Octo

  # The Segmentation module
  module Segmentation

    extend ActiveSupport::Concern

    module Helpers

      class << self

        # Helper method for returning operators as a hash to be used in UX
        # @return [Array<Hash{Symbol => String }>] The hash containing key :text
        #   as the text to display, and another key :id as the id to be used
        #   as reference while communicating
        def operators_as_choice
          mapping_as_choice operator_text
        end

        # Helper method for returning dimensions as choice to be used in the UX
        # @return [Array<Hash{Symbol => String }>] The hash containing key :text
        #   as the text to display, and another key :id as the id to be used
        #   as reference while communicating
        def dimensions_as_choice
          mapping_as_choice dimension_text
        end

        # Returns logic operatos as a choice for operating between dimensions
        def logic_operators_as_choice
          mapping_as_choice logic_text
        end

        # Helper method to return valid choices for a given dimension. It tries
        #   to find the values from db first. In case, there is nothing, it
        #   shows some default values, so the dashboard does not look totally
        #   blank.
        # @param [Fixnum] dimension The dimension ID for which choices to be
        #   found
        # @param [String] enterprise_id The enterprise ID for which the choices
        #   to be found
        def choices_for_dimensions(dimension, enterprise_id)
          args = {
            enterprise_id: enterprise_id,
            dimension: dimension
          }
          res = Octo::DimensionChoice.where(args)
          choices = Array.new
          if res.count > 0
            choices = res.collect do |r|
              r.column
            end
          elsif dimension_choice.has_key?(dimension)
            func = dimension_choice[dimension]
            choices = self.send(func, enterprise_id)
          end
          mapping_as_choice Hash[Array.new(choices.count) { |i| i }.zip(choices)]
        end


        private

        def operator_text
          {
            Octo::Segmentation::Operators::EQUAL => '= Equals',
            Octo::Segmentation::Operators::NOT_EQUAL => '!= Not Equals',
            Octo::Segmentation::Operators::GTE => '>= Greater than Or Equals',
            Octo::Segmentation::Operators::GT => '> Greater than',
            Octo::Segmentation::Operators::LTE => '<= Less than Or Equals',
            Octo::Segmentation::Operators::LT => '< Less than',
            Octo::Segmentation::Operators::IN => 'Within range'
          }
        end

        def dimension_choice
          {
            Octo::Segmentation::Dimensions::CITY => :city_choices,
            Octo::Segmentation::Dimensions::STATE => :state_choices,
            Octo::Segmentation::Dimensions::COUNTRY => :country_choices,
            Octo::Segmentation::Dimensions::OS => :os_choices,
            Octo::Segmentation::Dimensions::MANUFACTURER => :manufacturer_choices,
            Octo::Segmentation::Dimensions::BROWSER => :browser_choices,
            Octo::Segmentation::Dimensions::MODEL => :model_choices,
            Octo::Segmentation::Dimensions::ENGAGEMENT => :engagement_choices
          }
        end

        def dimension_text
          {
            Octo::Segmentation::Dimensions::CITY => 'City',
            Octo::Segmentation::Dimensions::STATE => 'State',
            Octo::Segmentation::Dimensions::COUNTRY => 'Country',
            Octo::Segmentation::Dimensions::OS => 'OS',
            Octo::Segmentation::Dimensions::MANUFACTURER => 'Manufacturer',
            Octo::Segmentation::Dimensions::BROWSER => 'Browser',
            Octo::Segmentation::Dimensions::MODEL => 'Model',
            Octo::Segmentation::Dimensions::ENGAGEMENT => 'Engagement',
            Octo::Segmentation::Dimensions::LAST_ACTIVE => 'Last Active On',
            Octo::Segmentation::Dimensions::CREATED_ON => 'Created On'
          }
        end

        def logic_text
          {
            Octo::Segmentation::Operators::AND => 'AND',
            Octo::Segmentation::Operators::OR  => 'OR',
            Octo::Segmentation::Operators::NOT => 'NOT',
            Octo::Segmentation::Operators::XOR => 'XOR',
          }
        end

        # Generates the city choices for the enterprise
        # @param [String] enterprise_id The enterpriseID for which city choices
        #   to be found
        # @return [Array<String>] Array of string values
        def city_choices(enterprise_id=nil)
          ['New Delhi', 'Mumbai', 'Bengaluru', 'San Francisco', 'Seattle']
        end

        def state_choices(enterprise_id=nil)
          ['Delhi', 'Maharashtra', 'Karnataka', 'California']
        end

        def country_choices(enterprise_id=nil)
          ['India', 'United States of America (USA)']
        end

        def os_choices(enterprise_id=nil)
          ['Windows', 'OS X', 'iOS', 'android']
        end

        def manufacturer_choices(enterprise_id=nil)
          ['Apple', 'Dell', 'HP', 'Samsung', 'Micromax']
        end

        def browser_choices(enterprise_id=nil)
          ['Firefox', 'Chrome', 'Safari']
        end

        def model_choices(enterprise_id=nil)
          ['iPhone 6', 'iPhone 6s', 'iPhone 5', 'Samsung S6']
        end

        def engagement_choices(enterprise_id=nil)
          ['Highly Engaged', 'Moderately Engaged', 'Low engaged', 'Not Engaged']
        end


        # Converts a hash mapping into choices ready for UX
        # @return [Array<Hash{Symbol => String }>] The hash containing key :text
        #   as the text to display, and another key :id as the id to be used
        #   as reference while communicating
        def mapping_as_choice(map)
          map.inject([]) do | choices, pair |
            key, val = pair
            choices << { text: val, id: key }
          end
        end

      end
    end

    module SegmentType

      USER  = 0
      EVENT = 1
    end

    # The Operators modules. Defines Operators and necessary methods around
    module Operators

      EQUAL           = 0
      NOT_EQUAL       = 1
      GTE             = 2
      GT              = 3
      LTE             = 4
      LT              = 5
      IN              = 6
      AND             = 7
      OR              = 8
      NOT             = 9
      XOR             = 10

      class << self

        # Returns if the given operator is valid or not
        def valid?(operator)
          Set.new([EQUAL, NOT_EQUAL, GTE, GT, LTE, LT, IN]).include?(operator.to_i)
        end

      end
    end

    # The Dimensions module. Defines the dimensions possible and its abstraction
    module Dimensions

      # Geographical Dimensions seems most obvious
      CITY          = 0
      STATE         = 1
      COUNTRY       = 2

      # Followed by User's device details
      OS            = 3
      MANUFACTURER  = 4
      BROWSER       = 5
      MODEL         = 6

      # Followed by User's engagement patterns
      ENGAGEMENT      = 7

      # What about their last active, created dates
      LAST_ACTIVE     = 8
      CREATED_ON      = 9

      # Usage Pattern
      DAYTIME_USAGE   = 10


    end

    # Extend
    module ClassMethods

      # Returns a boolean specifying if the segment is a valid choice or not
      # @param [String] segment The string to be evaluated
      # @return [Boolean] If the provided string exists in valid choices
      def is_valid_segment segment
        all_segment_choices.include?segment
      end

      # Returns all possible segment choices. Segment choices are the first
      #   data point that is picked on top of which segment would be made. It
      #   could be one of the supported octo events (eg: app.init etc) or users
      def all_segment_choices
        valid_events << :users
      end

      private

      # Get all the valid events
      # @return [Set<Symbol>] Valid events globally
      def valid_events
        Set.new(Octo.get_config(:allowed_events))
      end



      # Merges choices and returns the set with opts taken care of
      # @param [Array] c The initial choices
      # @param [Hash] opts Optional hash specifying anything to be exluded or
      #   included
      # @option opts [Array<String>] :include Strings to be included in choices
      # @option opts [Array<String>] :exclude Strings to be excluded in choices
      # @return [Array<String>] Merged choices
      def merge_choices(c, opts={})
        Set.new(c).merge(
          Set.new(opts.fetch(:include, []))
        ).subtract(
          Set.new(opts.fetch(:exclude, []))
        )
      end


    end

  end
end

