require 'octocore'

module Octo
  module Mailer
    class SubscriberMailer
      @queue = :subscriber_notifier

      # Method for the scheduler to call
      # Counts the number of subscriber in the last 24 hours
      #  and then sends a mail with subscriber count to the
      #  email mentioned

      def perform (from=nil)
        if from.nil?
          subscribers = Octo::Subscriber.where(created_at: 24.hours.ago..Time.now.floor)
        else
          subscribers = Octo::Subscriber.where(created_at: from..Time.now.floor)
        end
        #   MAIL CODE
        Octo.get_config(:email_to).each { |x|
          opts1 = {
              text: "Today number of new susbcribes are " + subscribers.length,
              name: x.fetch('name')
          }
          Octo::Email.send(x.fetch('email'), subject, opts1)
        }
        end
      end
  end
end


