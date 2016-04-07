require 'cequel'

module Octo
  class Enterprise
    include Cequel::Record

    # Set ttl of 120 minutes for the caches
    TTL = 120

    key :id, :uuid, auto: true
    column :name, :varchar

    has_many :users
    has_many :app_inits

  end

end
