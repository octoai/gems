require 'cequel'
require 'set'
require 'legato'

module Octo
  module GA

    # The Pageview class.
    class Pageview
      include Cequel::Record
      
      extend Legato::Model

      key :id, :uuid, auto: true

      metrics :pageviews
      dimensions :pagePath
    end
  end
end

