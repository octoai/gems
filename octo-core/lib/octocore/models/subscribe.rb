require 'cequel'

module Octo

  class Subscribe
    include Cequel::Record

    key :email, :text
    column :created_at, :timestamp

  end
end