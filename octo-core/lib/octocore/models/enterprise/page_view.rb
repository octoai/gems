require 'cequel'

module Octo
  class PageView
    include Cequel::Record

    belongs_to :enterprise, class_name: 'Octo::Enterprise'

    key :userid,     :bigint
    key :created_at, :timestamp

    column :routeurl, :text

    column :customid, :uuid, :index => true
  end
end
