require 'cequel'

require 'octocore/counter'
require 'octocore/schedeuleable'

module Octo

  # Counters for notifications sent
  class NotificationHit

    include Cequel::Record
    extend Octo::Counter
    extend Octo::Scheduleable

    max_type Octo::Counter::TYPE_DAY

    belongs_to :enterprise, class_name: 'Octo::Enterprise'

    countables

    def self.time_slots
      Array.new(6) { |i| "s_#{ i }" }
    end

    def self.fakedata(args)
      opts = {
        bod: false,
        step: 1.day
      }
      self.time_slots.concat([:ios, :android]).inject([]) do |res, uid|
        values = {
            count: rand(500..900),
          }
        _args = args.merge(uid: uid)
        res << self.fake_data_with(_args, values, opts)
        res.flatten
      end
    end

  end
end

