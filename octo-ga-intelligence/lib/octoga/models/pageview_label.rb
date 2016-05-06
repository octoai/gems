require 'set'
require 'legato'

module Octo
  module GA

    # The Pageview class. This class measures pageviews
    #   as labels
    class PageviewLabel
      extend Legato::Model

      metrics :totalEvents
      dimensions :eventLabel, :date

      filter :long_tail, &lambda {gte(:totalEvents, 7)}
    end
  end
end

