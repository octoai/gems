require 'cequel'

module Octo
  class ApiTrack
    include Cequel::Record

    key :customid, :uuid
    column :created_at, :timestamp
    column :json_dump, :text
    column :type, :text, index: true

  end
end
