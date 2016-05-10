require 'cequel'
require 'set'
require 'legato'

module Octo
  module GA

    # The Pageview class. This class measures pageviews
    #   as labels
    class Profiles
      include Cequel::Record

      key :id, :text
      key :name, :text
      column :ga_id, :text
      column :websiteUrl, :text
    end
  end
end

