require 'sinatra/base'
require 'octocore/helpers/sinatra_helper'

module Octo
  module NewsFeed

    module WebServiceHelper

      # Get newsfeed for a user
      # @param [String] enterprise_id The enterpriseid of enterprise
      # @param [Fixnum] user_id The user id of the user
      # @param [Hash] opts The options hash.
      # @option opts [Fixnum] :page The page of newsfeed to fetch
      # @option opts [Time] :ts The time at which newsfeed should be
      #   generated
      # @return [JSON] A json value representing the newsfeed or the
      #   error response
      def get_newsfeed_for(enterprise_id, user_id, opts = {})
        args = {
            enterprise_id: enterprise_id,
            user_id: user_id
        }
        user = Octo::User.where(args).first
        if user
          Octo::NewsFeed::News.feed_for(user, opts).to_json
        else
          {status: 404, message: 'User not found'}.to_json
        end
      end
    end

    # WebService class for Newsfeed
    class WebService < ::Sinatra::Base
      extend Octo::Sinatra::Helper
      extend Octo::NewsFeed::WebServiceHelper

      configure do
        logger = Octo::ApiLogger.logger
        set logger: logger
      end

      # Define an enterprise facing endpoint.This endpoint should be
      #   front faced by kong, as it finds enterprise details implicitly
      #   from the HTTP headers set by kong
      get '/feed/:user_id/:page?' do
        content_type :json
        params.deep_symbolize_keys!
        eid = enterprise_details[:custom_id]
        opts = { page: params.fetch(:page, 1)}
        get_newsfeed_for(eid, params[:user_id], opts)
      end

      # Define a route for internal purposes. This may be the one
      #   that is not behind kong and needs to be told the
      #   enterprise_id
      get '/:enterprise_id/feed/:user_id/:page?' do
        content_type :json
        params.deep_symbolize_keys!
        opts = { page: params.fetch(:page, 1)}
        get_newsfeed_for(params[:enterprise_id], params[:user_id], opts)
      end
    end
  end
end
