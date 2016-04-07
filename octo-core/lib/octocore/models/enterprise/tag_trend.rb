require 'cequel'
require 'octocore/trends'

module Octo

  # Class for storing trending tag
  class TagTrend
    include Cequel::Record
    extend Octo::Trends

    belongs_to :enterprise, class_name: 'Octo::Enterprise'

    trendable

    trend_for 'Octo::TagHit'
    trend_class 'Octo::Tag'
  end
end

