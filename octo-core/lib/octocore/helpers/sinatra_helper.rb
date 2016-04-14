require 'octocore'

module Octo
  module Sinatra
    module Helper

      # The headers on which kong sends the authenticated details
      KONG_AUTH_HEADERS = %w(HTTP_X_CONSUMER_ID HTTP_X_CONSUMER_CUSTOM_ID HTTP_X_CONSUMER_USERNAME)

      # Finds the enterprise details
      # #return [Array<String>] Enterprise's Id, Custom Name and User Name
      def enterprise_details
        KONG_AUTH_HEADERS.collect do |prop|
          request.env.fetch(prop, nil)
        end
      end


    end
  end

end