require 'cequel'

module Octo
  class Authorization
    include Cequel::Record

    belongs_to :enterprise, class_name: 'Octo::Enterprise'

    key :username, :text
    key :apikey, :text
    key :email, :text
    column :session_token, :text

    column :custom_id, :text
    column :password, :text

    timestamps
  end
end