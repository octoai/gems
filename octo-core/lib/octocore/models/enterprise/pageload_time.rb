require 'cequel/record'

module Octo

  class PageloadTime
    include Cequel::Record

    # Types of pageloads
    NEWSFEED = 0

    belongs_to :enterprise, class_name: 'Octo::Enterprise'
    key :pageload_type, :int
    key :counter_type, :int
    key :ts, :timestamp

    column :time, :int

    timestamps

    def self.fakedata(args)
      res = self.where(args)
      enterprise = Octo::Enterprise.find_by_id(args[:enterprise_id])
      if res.count == 0 and enterprise.fakedata?
        res = []
        ts = args.fetch(ts, 7.days.ago..Time.now.floor)
        if ts.class == Range
          start_time = ts.begin.beginning_of_day
          end_time = ts.end.end_of_day
          start_time.to(end_time, 1.day).each do |_ts|
            _args = args.merge({ ts: _ts, time: (rand(5.0..7.0)*60).to_i })
            res << self.new(_args).save!
          end
        elsif ts.class == Time
          _args = args.merge({ time: (rand(5.0..7.0)).to_i })
          res << self.new(args).save!
        end
      end
      res
    end

  end
end

