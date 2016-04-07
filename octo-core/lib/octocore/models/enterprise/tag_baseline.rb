require 'cequel'

require 'octocore/baseline'

module Octo
  class TagBaseline
    include Cequel::Record
    extend Octo::Baseline


    belongs_to :enterprise, class_name: 'Octo::Enterprise'

    baselineable

    # Specify the type of counter
    baseline_for 'Octo::TagHit'
  end
end
