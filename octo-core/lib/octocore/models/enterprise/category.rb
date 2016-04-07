require 'cequel'
require 'octocore/record'

module Octo
  class Category
    include Cequel::Record
    include Octo::Record

    belongs_to :enterprise, class_name: 'Octo::Enterprise'

    key :cat_text, :text
    timestamps
  end
end
