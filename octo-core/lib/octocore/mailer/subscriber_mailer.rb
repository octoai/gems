require 'octocore'
module Octo
  module Mailer
    class SubscriberMailer
      @queue = :subscriber_notifier

      def perform (from=nil)
        if from.nil?
          subscribers = Octo::Subscriber.where(created_at: 24.hours.ago..Time.now.floor)
        else
          subscribers = Octo::Subscriber.where(created_at: from..Time.now.floor)
        end
        puts subscribers.length
        #   MAIL CODE
        # Octo.get_config(:email_to).each { |x|
        #   opts1 = {
        #       text: "Today number of new susbcribes are " + subscribers.length,
        #       name: x.fetch('name')
        #   }
        #   Octo::Email.send(x.fetch('email'), subject, opts1)
        # }
        end
      end
  end
end

