require 'cequel'

module Octo
  class ProductPageView
    include Cequel::Record
    belongs_to :enterprise, class_name: 'Octo::Enterprise'
    
    key :userid, :bigint
    key :created_at, :timestamp, order: :desc
    
    column :product_id, :bigint
  end
end
