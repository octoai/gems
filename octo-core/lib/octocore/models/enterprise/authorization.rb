require 'cequel'
require 'securerandom'
require 'octocore/helpers/kong_helper'

module Octo
  class Authorization
    include Cequel::Record
    include Octo::Helpers::KongHelper

    key :username, :text
    
    column :enterprise_id, :text
    column :email, :text
    column :apikey, :text
    column :session_token, :text
    column :custom_id, :text
    column :password, :text
    column :admin, :boolean

    before_create :check_api_key, :generate_password
    after_create :kong_requests

    after_destroy :kong_delete

    timestamps

    # Check or Generate client apikey
    def check_api_key
      if(self.apikey.nil?)
        self.apikey = SecureRandom.hex
      end
    end

    # Check or Generate client password
    def generate_password
      if(self.password.nil?)
        self.password = Digest::SHA1.hexdigest(self.username + self.enterprise_id)
      else
        self.password = Digest::SHA1.hexdigest(self.password + self.enterprise_id)
      end
    end

    # Perform Kong Operations after creating client
    def kong_requests
      url = '/consumers/'
      payload = {
        username: self.username,
        custom_id: self.enterprise_id
      }

      process_kong_request(url, :PUT, payload)
      create_keyauth( self.username, self.apikey)
    end

    # Delete Kong Records
    def kong_delete
      delete_consumer(self.username)
    end

  end
end