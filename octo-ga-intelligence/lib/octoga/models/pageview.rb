require 'set'
require 'legato'

module Octo
  module GA

    # The Pageview class.
    class Pageview
      extend Legato::Model

      metrics :pageviews
      dimensions :pagePath
    end
  end
end

