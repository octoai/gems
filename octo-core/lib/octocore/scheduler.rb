require 'rake'
require 'resque'
require 'resque/tasks'
require 'resque/scheduler/tasks'

# Make sure dynamic scheduling is turned ON
Resque::Scheduler.dynamic = true

module Octo
  module Scheduler

    # Setup the schedules for counters.
    def setup_schedule_counters
      counter_classes = [
        Octo::ProductHit,
        Octo::CategoryHit,
        Octo::TagHit,
        Octo::ApiHit
      ]
      counter_classes.each do |clazz|
        clazz.send(:get_typecounters).each do |counter|
          name = [clazz, counter].join('::')
          config = {
            class: clazz.to_s,
            args: [counter],
            cron: '* * * * *',
            persist: true,
            queue: 'high'
          }
          Resque.set_schedule name, config
        end
      end
    end
  end
end