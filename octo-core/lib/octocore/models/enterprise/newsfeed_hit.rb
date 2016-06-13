require 'cequel'

require 'octocore/counter'
require 'octocore/schedeuleable'

module Octo

  class NewsfeedHit
    include Cequel::Record
    extend Octo::Counter

    extend Octo::Scheduleable

    COUNTERS = 20

    # Specify that we do not want any granularity more than
    # TYPE_DAY
    max_type Octo::Counter::TYPE_DAY

    belongs_to :enterprise, class_name: 'Octo::Enterprise'

    countables

    def self.fakedata(args)
      res = self.where(args)

      enterprise = Octo::Enterprise.find_by_id(args[:enterprise_id])
      if res.count == 0 and enterprise.fakedata?
        unless args.has_key?(:uid)
          args[:uid] = 'newsfeed'
        end
        res = []
        ts = args.fetch(:ts, 7.days.ago..Time.now)
        if ts.class == Range
          start_ts = ts.begin.beginning_of_day
          end_ts = ts.end.end_of_day
          start_ts.to(end_ts, 1.day).each do |_ts|
            _args = args.merge({ ts: _ts, count: rand(400..700) })
            res << self.new(_args).save!
          end
        elsif ts.class == Time
          _args = args.merge({ count: rand(400..800) })
          res << self.new(_args).save!
        end
      end
      res
    end


  end
end

