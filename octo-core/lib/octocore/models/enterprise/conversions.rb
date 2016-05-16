require 'cequel'
require 'octocore/record'

module Octo

  # The conversions store
  class Conversions

    # Types of conversions
    NEWSFEED            = 0
    PUSH_NOTIFICATION   = 1
    EMAIL               = 2

    belongs_to :enterprise, class_name: 'Octo::Enterprise'

    key :type, :int
    key :ts, :timestamp

    column :value, :float

    class << self

      # Fetches the types of conversions possible
      # @return [Hash] The conversion name and its value hash
      def types
        {
          'Newsfeed' => Octo::Conversions::NEWSFEED,
          'Push Notification' => Octo::Conversions::PUSH_NOTIFICATION,
          'Email' => Octo::Conversions::EMAIL
        }
      end

      def data(type, ts = Time.now.floor)
        args = {
          enterprise_id: self.enterprise.id,
          type: type,
          ts: ts
        }
        res = self.where(args)
        if res.count > 0
          res
        else
          args.merge!({ value: rand(10.0..67.0) })
          self.new().save!
        end
      end

    end
  end

end

