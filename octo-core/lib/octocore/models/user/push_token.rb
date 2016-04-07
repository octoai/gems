require 'cequel'

module Octo
  class PushToken
    include Cequel::Record

    belongs_to :user, class_name: 'Octo::User'

    key :push_type, :bigint
    column :pushtoken, :text

    timestamps
  end
end

