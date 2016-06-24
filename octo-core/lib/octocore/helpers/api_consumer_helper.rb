require 'json'
require 'set'

module Octo
  module Helpers

    module ApiConsumerHelper

      # Get all the valid events
      # @return [Set<Symbol>] Valid events globally
      def valid_events
        Set.new(Octo.get_config(:allowed_events))
      end

      # Get the API events. These are the ones that the client is billed for
      #   This should eventually be placed under kong helpers when that is
      #   ready
      # @return [Set<Symbol>] Set of api_events
      def api_events
        Set.new(%w(app.init app.login app.logout page.view productpage.view update.profile))
      end

      def handle(msg)
        msg_dump = msg
        msg = parse(msg)

        eventName = msg.delete(:event_name)

        if valid_events.include?eventName
          enterprise = checkEnterprise(msg)
          unless enterprise
            Octo.logger.info 'Unable to find enterprise. Something\'s wrong'
          end
          user = checkUser(enterprise, msg)

          hook_opts = {
              enterprise: enterprise,
              user: user
          }

          if api_events.include?eventName
            hook_opts[:event] = register_api_event(enterprise, eventName)
          end

          Octo::ApiTrack.new(customid: msg[:id],
                            created_at: Time.now,
                            json_dump: msg_dump,
                            type: eventName).save!

          case eventName
            when 'app.init'
              Octo::AppInit.new(enterprise: enterprise,
                                created_at: Time.now,
                                userid: user.id).save!
              updateUserDeviceDetails(user, msg)
              call_hooks(eventName, hook_opts)
            when 'app.login'
              Octo::AppLogin.new(enterprise: enterprise,
                                 created_at: Time.now,
                                 userid: user.id).save!
              updateUserDeviceDetails(user, msg)
              call_hooks(eventName, hook_opts)
            when 'app.logout'
              event = Octo::AppLogout.new(enterprise: enterprise,
                                          created_at: Time.now,
                                          userid: user.id).save!
              updateUserDeviceDetails(user, msg)
              call_hooks(eventName, hook_opts)
            when 'page.view'
              page, categories, tags = checkPage(enterprise, msg)
              Octo::PageView.new(enterprise: enterprise,
                                 created_at: Time.now,
                                 userid: user.id,
                                 routeurl: page.routeurl
              ).save!
              updateUserDeviceDetails(user, msg)
              call_hooks(eventName, hook_opts)
            when 'productpage.view'
              product, categories, tags = checkProduct(enterprise, msg)
              Octo::ProductPageView.new(
                                       enterprise: enterprise,
                                       created_at: Time.now,
                                       userid: user.id,
                                       product_id: product.id
              ).save!
              updateUserDeviceDetails(user, msg)
              hook_opts.merge!({ product: product,
                                 categories: categories,
                                 tags: tags })
              call_hooks(eventName, hook_opts)
            when 'update.profile'
              checkUserProfileDetails(enterprise, user, msg)
              updateUserDeviceDetails(user, msg)
              call_hooks(eventName, hook_opts)
            when 'update.push_token'
              checkPushToken(enterprise, user, msg)
              checkPushKey(enterprise, msg)
          end
        end
      end

      private

      def register_api_event(enterprise, event_name)
        Octo::ApiEvent.findOrCreate({ enterprise_id: enterprise.id,
                                      eventname: event_name})
      end

      def call_hooks(event, *args)
        hook = [:after, event.gsub('.', '_')].join('_').to_sym
        Octo::Callbacks.run_hook(hook, *args)
      end

      def checkUserProfileDetails(enterprise, user, msg)
        args = {
          user_id: user.id,
          user_enterprise_id: enterprise.id,
          email: msg[:profileDetails].fetch('email')
        }
        opts = {
          username: msg[:profileDetails].fetch('username', ''),
          gender: msg[:profileDetails].fetch('gender', ''),
          dob: msg[:profileDetails].fetch('dob', ''),
          alternate_email: msg[:profileDetails].fetch('alternate_email', ''),
          mobile: msg[:profileDetails].fetch('mobile', ''),
          extras: msg[:profileDetails].fetch('extras', '{}').to_s
        }
        Octo::UserProfileDetails.findOrCreateOrUpdate(args, opts)
      end

      # Checks for push tokens and creates or updates it
      # @param [Octo::Enterprise] enterprise The Enterprise object
      # @param [Octo::User] user The user to whom this token belongs to
      # @param [Hash] msg The message hash
      # @return [Octo::PushToken] The push token object corresponding to this user
      def checkPushToken(enterprise, user, msg)
        args = {
          user_id: user.id,
          user_enterprise_id: enterprise.id,
          push_type: msg[:pushType].to_i
        }
        opts = {
          pushtoken: msg[:pushToken]
        }
        Octo::PushToken.findOrCreateOrUpdate(args, opts)
      end

      # Checks for push keys and creates or updates it
      # @param [Octo::Enterprise] enterprise The Enterprise object
      # @param [Hash] msg The message hash
      # @return [Octo::PushKey] The push key object corresponding to this user
      def checkPushKey(enterprise, msg)
        args = {
            enterprise_id: enterprise.id,
            push_type: msg[:pushType].to_i
        }
        opts = {
            key: msg[:pushKey]
        }
        Octo::PushKey.findOrCreateOrUpdate(args, opts)
      end

      # Check if the enterprise exists. Create a new enterprise if it does
      #   not exist. This method makes sense because the enterprise authentication
      #   is handled by kong. Hence we can be sure that all these enterprises
      #   are valid.
      # @param [Hash] msg The message hash
      # @return [Octo::Enterprise] The enterprise object
      def checkEnterprise(msg)
        Octo::Enterprise.findOrCreate({id: msg[:enterpriseId]},
                                      {name: msg[:enterpriseName]})
      end

      # Checks for user and creates if not exists
      # @param [Octo::Enterprise] enterprise The Enterprise object
      # @param [Hash] msg The message hash
      # @return [Octo::User] The push user object corresponding to this user
      def checkUser(enterprise, msg)
        args = {
            enterprise_id: enterprise.id,
            id: msg[:userId]
        }
        Octo::User.findOrCreate(args)
      end

      # Updates location for a user
      # @param [Octo::User] user The user to whom this token belongs to
      # @param [Hash] msg The message hash
      # @return [Octo::UserLocationHistory] The location history object
      #   corresponding to this user
      def updateLocationHistory(user, msg)
        Octo::UserLocationHistory.new(
            user: user,
            latitude: msg[:phone].fetch('latitude', 0.0),
            longitude: msg[:phone].fetch('longitude', 0.0),
            created_at: Time.now
        ).save!
      end

      # Updates user's device details
      # @param [Octo::User] user The user to whom this token belongs to
      # @param [Hash] msg The message hash
      def updateUserDeviceDetails(user, msg)
        args = {user_id: user.id, user_enterprise_id: user.enterprise.id}

        # Check Device Type
        if msg[:browser]
          updateUserBrowserDetails(args, msg)
        elsif msg[:phone]
          updateLocationHistory(user, msg)
          updateUserPhoneDetails(args, msg)
        end
      end

      # Updates user's phone details
      # @param [Hash] args The user details to whom this token belongs to
      # @param [Hash] msg The message hash
      # @return [Octo::UserPhoneDetails] The phone details object
      #   corresponding to this user
      def updateUserPhoneDetails(args, msg)
        opts = {deviceid: msg[:phone].fetch('deviceId', ''),
                manufacturer: msg[:phone].fetch('manufacturer', ''),
                model: msg[:phone].fetch('model', ''),
                os: msg[:phone].fetch('os', '')}
        Octo::UserPhoneDetails.findOrCreateOrUpdate(args, opts)
      end

      # Updates user's browser details
      # @param [Hash] args The user details to whom this token belongs to
      # @param [Hash] msg The message hash
      # @return [Octo::UserBrowserDetails] The browser details object
      #   corresponding to this user
      def updateUserBrowserDetails(args, msg)
        opts = {name: msg[:browser].fetch('name', ''),
                platform: msg[:browser].fetch('platform', ''),
                manufacturer: msg[:browser].fetch('manufacturer', ''),
                cookieid: msg[:browser].fetch('cookieid', '')}
        Octo::UserBrowserDetails.findOrCreateOrUpdate(args, opts)
      end

      # Checks the existence of a page and creates if not found
      # @param [Octo::Enterprise] enterprise The Enterprise object
      # @param [Hash] msg The message hash
      # @return [Array<Octo::Page, Array<Octo::Category>, Array<Octo::Tag>] The
      #   page object, array of categories objects and the array of tags
      #   object
      def checkPage(enterprise, msg)
        cats = checkCategories(enterprise, msg[:categories])
        tags = checkTags(enterprise, msg[:tags])

        args = {
            enterprise_id: enterprise.id,
            routeurl: msg[:routeUrl]
        }
        opts = {
            categories: Set.new(msg[:categories]),
            tags: Set.new(msg[:tags])
        }
        page = Octo::Page.findOrCreateOrUpdate(args, opts)
        [page, cats, tags]
      end

      # Checks for existence of a product and creates if not found
      # @param [Octo::Enterprise] enterprise The Enterprise object
      # @param [Hash] msg The message hash
      # @return [Array<Octo::Product, Array<Octo::Category>, Array<Octo::Tag>] The
      #   product object, array of categories objects and the array of tags
      #   object
      def checkProduct(enterprise, msg)
        categories = checkCategories(enterprise, msg[:categories])
        tags = checkTags(enterprise, msg[:tags])

        args = {
            enterprise_id: enterprise.id,
            id: msg[:productId]
        }
        opts = {
            categories: Set.new(msg[:categories]),
            tags: Set.new(msg[:tags]),
            price: msg[:price].to_f.round(2),
            name: msg[:productName],
            routeurl: msg[:routeUrl]
        }
        prod = Octo::Product.findOrCreateOrUpdate(args, opts)
        [prod, categories, tags]
      end

      # Checks for categories and creates if not found
      # @param [Octo::Enterprise] enterprise The enterprise object
      # @param [Array<String>] categories An array of categories to be checked
      # @return [Array<Octo::Category>] An array of categories object
      def checkCategories(enterprise, categories)
        categories.collect do |category|
          Octo::Category.findOrCreate({enterprise_id: enterprise.id,
                                       cat_text: category})
        end
      end

      # Checks for tags and creates if not found
      # @param [Octo::Enterprise] enterprise The enterprise object
      # @param [Array<String>] tags An array of tags to be checked
      # @return [Array<Octo::Tag>] An array of tags object
      def checkTags(enterprise, tags)
        tags.collect do |tag|
          Octo::Tag.findOrCreate({enterprise_id: enterprise.id, tag_text: tag})
        end
      end

      def parse(msg)
        msg2 = JSON.parse(msg)
        msg = msg2
        enterprise = msg['enterprise']
        raise StandardError, 'Parse Error' if enterprise.nil?

        eid = if enterprise.has_key?'custom_id'
                enterprise['custom_id']
              elsif enterprise.has_key?'customId'
                enterprise['customId']
              end

        ename = if enterprise.has_key?'user_name'
                  enterprise['user_name']
                elsif enterprise.has_key?'userName'
                  enterprise['userName']
                end
        m = {
            id:             msg['uuid'],
            enterpriseId:   eid,
            enterpriseName: ename,
            event_name:     msg['event_name'],
            phone:          msg.fetch('phoneDetails', nil),
            browser:        msg.fetch('browserDetails', nil),
            userId:         msg.fetch('userId', -1),
            created_at:     Time.now
        }
        case msg['event_name']
          when 'update.profile'
            m.merge!({
                        profileDetails: msg['profileDetails']
                    })
          when 'page.view'
            m.merge!({
                        routeUrl:     msg['routeUrl'],
                        categories:   msg['categories'],
                        tags:         msg['tags']
                     })
          when 'productpage.view'
            m.merge!({
                        routeUrl:     msg['routeUrl'],
                        categories:   msg['categories'],
                        tags:         msg['tags'],
                        productId:    msg['productId'],
                        productName:  msg['productName'],
                        price:        msg['price']
                     })
          when 'update.push_token'
            m.merge!({
                        pushType:     msg['notificationType'],
                        pushKey:      msg['pushKey'],
                        pushToken:    msg['pushToken']
                     })
        end
        m
      end
    end
  end
end
