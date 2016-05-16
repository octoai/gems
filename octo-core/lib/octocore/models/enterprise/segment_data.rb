require 'cequel'
require 'octocore/record'
require 'set'

module Octo

  # The SegmentData class. This class holds data for the segments
  class SegmentData

    include Cequel::Record
    include Octo::Record

    belongs_to :enterprise, class_name: 'Octo::Enterprise'

    key :segment_slug, :text  # Using key as segment name's slug

    key :ts, :timestamp    # The timestamp at which data is collected
    list :value, :float       # List of values containing data collected

  end
end

