require 'net/http'
require 'uri'
require 'json'
require 'digest/sha1'
require 'securerandom'

module Octo
  module Helpers
    module KongHelper

      # Fetch Kong URL
      # @return [String] Kong URL
      def kong_url
        kong_config = Octo.get_config :kong
        if kong_config.has_key?(:url)
          kong_config[:url]
        else
          'http://127.0.0.1:8001'
        end
      end

      # Process Every Kong Request 
      # @param [String] url The url of the kong request
      # @param [Key] method The request method
      # @param [Hash] payload The request body
      # @return [Hash] Response
      def process_kong_request (url, method, payload)
        begin

          url = kong_url + url
          header = {
            'Accept' => 'application/json, text/plain, */*',
            'Content-Type' => 'application/json'
          }
          uri = URI.parse(url)
          http = Net::HTTP.new(uri.host,uri.port)
          
          case method
          when :GET
            header = {'Accept' => 'application/json, text/plain, */*'}
            req = Net::HTTP::Get.new(uri, header) # GET Method
          when :POST
            req = Net::HTTP::Post.new(uri.path, header) # POST Method
          when :PUT
            req = Net::HTTP::Put.new(uri.path, header) # PUT Method
          when :PATCH
            req = Net::HTTP::Patch.new(uri.path, header) # PATCH Method
          when :DELETE
            req = Net::HTTP::Delete.new(uri.path, header) # DELETE Method
          else
            # Default Case
          end

          req.body = "#{ payload.to_json }"
          res = http.request(req)
          JSON.parse(res.body) # Returned Data
        rescue Exception => e
          { message: e.to_s }.to_json
        end
      end

      # Add Key of client for Key Authorization
      # @param [String] username The username of the client
      # @param [String] keyauth_key The Authorization key of the client
      # @return [Hash] Response
      def create_keyauth(username, keyauth_key)

        url = '/consumers/'+ username +'/key-auth'
        payload = {
          key: keyauth_key
        }
        process_kong_request(url, :POST, payload)
      end

      # Add a Kong ratelimiting plugin
      # @param [String] apikey The apikey of the client
      # @param [String] consumer_id The consumer_id of the client
      # @param [String] config The configuration of the plugin
      # @return [String] Plugin Id
      def add_ratelimiting_plugin(apikey, consumer_id, config)

        url = '/apis/' + apikey + '/plugins/'
        payload = {
          name: "rate-limiting",
          consumer_id: consumer_id,
          config: config
        }
      
        response = process_kong_request(url, :POST, payload)

        if response['id']
          response['id'].to_s
        end
      end

      # Create a new Client
      # @params [Hash] Consumer list filter values - id, custom_id, username, size, offset
      # @return [Hash] All the clients data
      def consumerlist(payload = {})
        
        url = '/consumers/'
        res = process_kong_request(url, :GET, payload)
        res['data']
      end

      # Delete Consumers from Kong
      # @params [String] username The username of the Client
      # @return [String] Status
      def delete_consumer(username)
        url = '/consumers/' + username
        payload = {}
        process_kong_request(url, :DELETE, payload)
      end

    end
  end
end