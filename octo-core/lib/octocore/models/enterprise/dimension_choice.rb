require 'cequel'
require 'octocore/record'

module Octo

  # Choices for dimensions
  class DimensionChoice

    include Cequel::Record
    include Octo::Record

    belongs_to :enterprise, class_name: 'Octo::Enterprise'

    key :dimension, :int
    column :choice, :text

    timestamps

  end
end

