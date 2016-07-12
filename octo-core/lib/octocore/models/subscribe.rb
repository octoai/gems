require 'cequel'

# Model for Subscribe to us (in the footer), on the microsite
module Octo

  class Subscriber
    include Cequel::Record

    key :email, :text
    key :created_at, :timestamp

  end
end