require 'cequel'

module Octo
  class FunnelTracker
    include Cequel::Record

    belongs_to :enterprise, class_name: 'Octo::Enterprise'

    key :userid, :bigint
    key :created_at, :timestamp
    column :type, :text
  end
end