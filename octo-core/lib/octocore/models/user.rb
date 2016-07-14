require 'cequel'

module Octo
  class User
    include Cequel::Record

    belongs_to :enterprise, class_name: 'Octo::Enterprise'

    key :id, :bigint

    timestamps

    # Define the associations
    has_many :user_location_histories
    has_many :user_phone_details
    has_many :push_token
    has_many :user_browser_details
    has_many :user_personas

  end
end

