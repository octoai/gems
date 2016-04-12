module Octo
  module Config

    def self.included(base)
      base.include InstanceMethods
      base.extend ClassMethods
    end

    module InstanceMethods

    end

    module ClassMethods

      def load_config(opts)
        curr_config.merge!opts
      end

      def set_config(key, val)
        curr_config[key] = val
      end

      def get_config(key, default = nil)
        curr_config.fetch(key, default)
      end

      def curr_config
        @config = Hash.new({}) unless @config
        @config
      end
    end
  end
end

module Octo
  include Octo::Config
end