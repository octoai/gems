require 'cequel'

module Octo
  class FunnelTracker
    include Cequel::Record

    key :enterprise_id, :uuid

    key :p1, :text
    key :direction, :int
    key :p2, :text
    column :weight, :counter
  end
end