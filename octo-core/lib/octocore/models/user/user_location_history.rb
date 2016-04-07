require 'cequel'

module Octo
  class UserLocationHistory
    include Cequel::Record

    belongs_to :user, class_name: 'Octo::User'

    key :created_at, :timestamp

    column :latitude, :float
    column :longitude, :float
  end
end

