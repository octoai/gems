require 'cequel'
require 'octocore/record'

module Octo

  # The conversions store
  class Conversions

    include Cequel::Record
    include Octo::Record

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
          'Notification' => Octo::Conversions::PUSH_NOTIFICATION,
#          'Email' => Octo::Conversions::EMAIL
        }
      end

      def data( enterprise_id, type, ts = 3.days.ago..Time.now.floor)
        args = {
          enterprise_id: enterprise_id,
          type: type,
          ts: ts
        }
        res = self.where(args)
        if res.count > 0
          res.first
        else
          res = []
          e = Octo::Enterprise.find_by_id(enterprise_id)
          if e.fakedata?
            if ts.class == Range
              ts_begin = ts.begin.floor
              ts_end = ts.end.floor
              ts_begin.to(ts_end, 1.day).each do |_ts|
                _args = args.merge( ts: _ts, value: rand(10.0..67.0))
                res << self.new(_args).save!
              end
            elsif ts.class == Time
              args.merge!({ value: rand(10.0..67.0) })
              res << self.new(args).save!
            end
          end
        end
        res
      end

    end
  end

end

