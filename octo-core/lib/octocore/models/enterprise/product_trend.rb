require 'cequel'
require 'octocore/trends'

module Octo

  # Class for storing trending product
  class ProductTrend
    include Cequel::Record
    extend Octo::Trends

    belongs_to :enterprise, class_name: 'Octo::Enterprise'

    trendable

    trend_for 'Octo::ProductHit'
    trend_class 'Octo::Product'
  end
end