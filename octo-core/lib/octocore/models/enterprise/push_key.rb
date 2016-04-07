require 'cequel'

module Octo
  class PushKey
    include Cequel::Record

    belongs_to :enterprise, class_name: 'Octo::Enterprise'

    key :push_type, :bigint
    column :key, :text

    timestamps
  end
end

