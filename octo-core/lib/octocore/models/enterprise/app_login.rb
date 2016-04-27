require 'cequel'

module Octo
  class AppLogin
    include Cequel::Record

    belongs_to :enterprise, class_name: 'Octo::Enterprise'

    key :created_at, :timestamp
    key :userid, :bigint
  end
end
