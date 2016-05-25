require 'cequel'

module Octo
  class User
    include Cequel::Record
    belongs_to :enterprise, class_name: 'Octo::Enterprise'

    key :id, :bigint

    timestamps

    has_many :user_location_histories
  end
end

