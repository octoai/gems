require 'cequel'

require 'octocore/baseline'
require 'octocore/schedeuleable'

module Octo
  class ProductBaseline
    include Cequel::Record
    extend Octo::Baseline
    extend Octo::Scheduleable

    belongs_to :enterprise, class_name: 'Octo::Enterprise'

    baselineable

    # Specify the type of counter
    baseline_for 'Octo::ProductHit'

  end
end
