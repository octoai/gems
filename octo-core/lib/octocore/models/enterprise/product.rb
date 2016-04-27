require 'cequel'
require 'octocore/record'

module Octo
  class Product
    include Cequel::Record
    include Octo::Record

    belongs_to :enterprise, class_name: 'Octo::Enterprise'

    key :id, :bigint

    column :price, :float
    column :name, :text
    column :routeurl, :text

    set :categories, :text
    set :tags, :text

    timestamps
  end
end
