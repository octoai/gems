require 'cequel'

module Octo

  # Storage for Notifications
  class GcmNotification
    include Cequel::Record

    belongs_to :enterprise, class_name: 'Octo::Enterprise'

    key :gcmid, :varchar
    key :userid, :bigint

    column :score, :float
    column :ack, :boolean
    column :sent_at, :timestamp
    column :recieved_at, :timestamp

  end
end

