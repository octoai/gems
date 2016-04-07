require 'cequel'
require 'octocore/record'

module Octo
  class Tag
    include Cequel::Record
    include Octo::Record

    belongs_to :enterprise, class_name: 'Octo::Enterprise'

    key :tag_text, :text
    timestamps
  end
end
