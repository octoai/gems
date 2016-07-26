require 'rake'
require 'resque'
require 'resque/tasks'
require 'resque/scheduler/tasks'

# Make sure dynamic scheduling is turned ON
Resque::Scheduler.dynamic = true

module Octo
  module Scheduler

    # Setup the schedules for counters.
    def schedule_counters
      counter_classes = [
        Octo::ProductHit,
        Octo::CategoryHit,
        Octo::TagHit,
        Octo::ApiHit,
        Octo::NewsfeedHit
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

      # Schedules the processing of baselines
      def schedule_baseline
        baseline_classes = [
            Octo::ProductBaseline,
            Octo::CategoryBaseline,
            Octo::TagBaseline
        ]
        baseline_classes.each do |clazz|
          clazz.send(:get_typecounters).each do |counter|
            name = [clazz, counter].join('::')
            config = {
                class: clazz.to_s,
                args: [counter],
                cron: '* * * * *',
                persists: true,
                queue: 'baseline_processing'
            }
            Resque.set_schedule name, config
          end
        end
      end

      # Schedules the daily mail, to be sent at noon
      def schedule_subscribermail
        name = 'SubscriberDailyMailer'
        config = {
            class: Octo::Mailer::SubscriberMailer,
            args: [],
            cron: '0 0 * * *',
            persist: true,
            queue: 'subscriber_notifier'
        }
        Resque.set_schedule name, config
      end

    end
  end
end
