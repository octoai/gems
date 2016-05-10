require 'cequel'
require 'redis'

require 'octoga/models/pageview'
require 'octoga/models/pageview_label'
require 'octoga/models/profiles'

module Cequel
  module Record

    # Updates caching config
    # @param [String] host The host to connect to
    # @param [Fixnum] port The port to connect to
    def self.update_cache_config(host, port)
      @redis = Redis.new(host: host,
                         port: port,
                         driver: :hiredis)
    end

    # Getter for redis object
    # @return [Redis] redis cache instance
    def self.redis
      @redis
    end

    # Override Cequel::Record here
    module ClassMethods

    end
    
  end
end