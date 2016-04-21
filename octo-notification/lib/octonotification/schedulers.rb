require 'cequel'
require 'redis'
require 'resque'
require 'gcm'
require 'apns'
require 'json'
require 'aws-sdk'
require 'tempfile'

require 'octorecommender'
require 'octonotification/textgenerator'

module Octo
  class Schedulers
    @queue = :notification_schedule
    SCORE = 0.98 # Random Score

    # Resque Perform method
    # @param [Octo::User] user The details of a user
    def self.perform(user)
      products = trending_products(user)

      product = products.shuffle[0]
      template = user_template(user)

      msg = {}

      msg[:text] = Octo::TextGenerator.generate(product, template)
      msg[:userToken] = Octo::PushToken.where(user: user)

      msg[:pushKey] = Octo::PushKey.where(enterprise: user.enterprise)

      gcm_sender(msg, user.enterprise_id)

    end

    # Sending notification using GCM
    # @param [Hash] msg The details of notification
    # @param [String] eid Enterprise Id of the client
    def gcm_sender(msg, eid)
      apns_config = Octo.get_config :apns

      notification = {
        title: 'Check this out',
        body: msg[:text]
      }

      # some random score to be sent
      score = { score: SCORE }

      if msg.has_key?(:userToken)
        msg[:userToken].each do |pushtype, pushtoken|
          if pushtype == 2
            APNS.host = apns_config[:host]
            APNS.pem  = getPEMLocationForClient(eid)
            apnsresponse = APNS.send_notification(pushtoken, :alert => notification, :other => score )
          elsif [0, 1].include?(pushtype)
            gcmClientKey = msg[:pushKey][:key]
            gcm = GCM.new(gcmClientKey)
            registration_ids = [pushtoken]
            options = {data: score, notification: notification, content_available: true, priority: 'high'}
            gcmresponse = gcm.send(registration_ids, options)
          end
        end
      end

    end

    # Fetch IOS Certificate
    # @param [String] eid Enterprise Id of the client
    # @return [String] Path of the IOS certificate file
    def self.getPEMLocationForClient(eid)

      if Cequel::Record.redis.get(eid).nil?
        updatePEMLocation(eid)
      end

      if !File.exist?(Cequel::Record.redis.get(eid))
        updatePEMLocation(eid)
      end

      Cequel::Record.redis.get(eid)
    end

    def updatePEMLocation(eid)
      aws_config = Octo.get_config :aws
      certificate_config = Octo.get_config :ioscertificate

      Aws.config.update({
        region: aws_config[:region],
        credentials: Aws::Credentials.new( aws_config[:access_key], aws_config[:secret_key])
      })

      s3 = Aws::S3::Client.new
      object_key = eid + '/' + certificate_config[:filename]
      resp = s3.get_object(bucket: aws_config[:bucket_name], key: object_key)
      
      pem_file = Tempfile.new 'pem_file'
      pem_file.write resp.body.read
      pem_file.close

      Cequel::Record.redis.set( eid, pem_file.path)
    end

    # Fetch Trending Products
    # @param [Octo::User] user The details of the user
    # @return [Array<Octo::Product>] An array of Octo::Product recommended
    def trending_products(user)
      recommender = Octo::Recommender.new
      recommender.recommended_products(user)
    end

    # Fetch Notification Template
    # @param [Octo::User] user The details of the user
    # @return [String] Template Text
    def user_template(user)
      categories = Octo::Category.where(enterprise: user.enterprise)
      @templates = []
      categories.each do |category|
        temp = Octo::Template.where(enterprise: user.enterprise, category_type: category.text).first
        @templates.push(temp.template_text)
      end
      @templates.shuffle[0]
    end
    
  end
end