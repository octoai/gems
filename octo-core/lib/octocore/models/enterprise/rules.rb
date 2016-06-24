require 'cequel'
require 'octocore/record'

module Octo
  class Rules
    include Cequel::Record
    include Octo::Record

    # Types of conversions
    DAILY               = 0
    WEEKLY              = 1
    WEEKENDS            = 2
    ALTERNATE           = 3

    belongs_to :enterprise, class_name: 'Octo::Enterprise'

    key :name_slug, :text       # Name slug as rule
    key :active, :boolean       # Active or Not

    column :name, :text         # Name of the rule
    column :segment, :text      # slug name of segment
    column :template_cat, :text
    column :duration, :int     # Daily, weekly, weekends ,alternate days
    column :start_time, :timestamp
    column :end_time, :timestamp

    timestamps

    class << self

      # Fetches the types of durations
      # @return [Hash] The name and its duration value
      def duration_types
        {
          Octo::Rules::DAILY => 'Daily',
          Octo::Rules::WEEKLY => 'Weekly',
          Octo::Rules::WEEKENDS => 'Weekends',
          Octo::Rules::ALTERNATE => 'Alternate Days'
        }
      end
    end

  end
end

