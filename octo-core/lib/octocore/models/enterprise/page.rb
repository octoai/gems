require 'cequel'

module Octo
  class Page
    include Cequel::Record

    belongs_to :enterprise, class_name: 'Octo::Enterprise'

    key :routeUrl, :text

    column :customid, :uuid, :index => true

    set :categories, :text
    set :tags, :text
  end
end

