require 'net/http'
require 'uri'
require 'json'
require 'digest/sha1'
require 'securerandom'
require 'octocore/models'

module Octo
  module Helpers
    module ClientHelper

      # Create a new Client
      # @param [String] username The name of the client
      # @param [String] email The email of the client
      # @param [String] password The password of the client
      # @return [String] The status of request
      def add_consumer(username, email, password)
        unless enterprise_name_exists?(username)

          # create enterprise
          e = Octo::Enterprise.new
          e.name = username
          e.save!

          enterprise_id = e.id.to_s

          # create its Authentication stuff
          auth = Octo::Authorization.new
          auth.enterprise_id = enterprise_id
          auth.username = e.name
          auth.email = email
          custom_id = enterprise_id
          auth.password = password
          auth.save!
          'success'
        else
          'Not creating client as client name exists'
        end
      end

      # Validate Client authentication
      # @param [String] username The name of the client
      # @param [String] password The password of the client
      # @return [Boolean] Authenticated or not
      def validate_password( username, password)
        consumer = fetch_consumer(username)
        hash_password = Digest::SHA1.hexdigest(password + consumer.enterprise_id)
        hash_password == consumer.password
      end

      # check enterprise exist
      # @param [String] enterprise_name The name of the enterprise
      # @return [Boolean] Exist or not
      def enterprise_name_exists?(enterprise_name)
        Octo::Enterprise.all.select { |x| x.name == enterprise_name}.length > 0
      end

      # fetch client data
      # @param [String] username The name of the client
      # @return [Hash] Client Data
      def fetch_consumer(username)
        Octo::Authorization.where(username: username).first
      end

      # Validate Client session
      # @param [String] username The name of the client
      # @param [String] token The session token of the client
      # @return [Boolean] Authenticated or not
      def validate_token(username, token)
        Octo::Authorization.all.select do |x| 
          x.username == username &&
          x.session_token == token
        end.length > 0
      end

      # Create new client session
      # @param [String] username The name of the client
      # @return [String] Session Token
      def save_session(username)
        consumer = fetch_consumer(username)
        consumer.session_token = SecureRandom.hex
        consumer.save!
        consumer.session_token.to_s
      end

      # Destroy client session
      # @param [String] username The name of the client
      def destroy_session(username)
        consumer = fetch_consumer(username)
        consumer.session_token = nil
        consumer.save!
      end

      # check user is admin or client
      # @param [String] username The username of the client
      # @return [Boolean] Is Admin or not
      def check_admin(username)
        consumer = fetch_consumer(username)
        consumer.admin
      end

    end
  end
end
