require 'cequel'

require 'octocore/counter'
require 'octocore/trendable'
require 'octocore/schedeuleable'

module Octo

  class ProductHit
    include Cequel::Record
    extend Octo::Counter
    extend Octo::Trendable
    extend Octo::Scheduleable

    COUNTERS = 30

    belongs_to :enterprise, class_name: 'Octo::Enterprise'

    countables
    trendables

    baseline 'Octo::ProductBaseline'
    trends_class 'Octo::ProductTrend'

  end
end
