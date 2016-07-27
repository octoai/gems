require 'cequel'
require 'octocore/search/searchable'

module Octo
  class User
    include Cequel::Record
    include Octo::Search::Searchable

    belongs_to :enterprise, class_name: 'Octo::Enterprise'

    key :id, :bigint

    column :last_login,   :timestamp
    column :curr_city,    :text
    column :curr_state,   :text
    column :curr_country, :text

    column :home_location_lat, :float
    column :home_location_lon, :float

    column :work_location_lat, :float
    column :work_location_lon, :float

    timestamps

    # Define the associations
    has_many :user_location_histories, class_name: 'Octo::UserLocationHistory'
    has_many :user_phone_details, class_name: 'Octo::UserPhoneDetails'
    has_many :push_token, class_name: 'Octo::PushToken'
    has_many :user_browser_details, class_name: 'Octo::UserBrowserDetails'
    has_many :user_personas, class_name: 'Octo::UserPersona'


    # Returns the data for indexing purposess.
    def indexed_json
      i = Hash.new
      i.merge!({
        id: id,
        userid: id,
        enterpriseid: enterprise.id.to_s,
        created: created_at,
        updated: updated_at,
        last_login: last_login,
        device_id: device_ids,
        manufacturer: device_manufacturers,
        model: device_models
      })
      i[:city] = curr_city if curr_city
      i[:country] = curr_country if curr_country
      i[:state] = curr_state if curr_state
      i[:os] = os if os
      i[:browser] = browsers if browsers.count > 0
      i[:engagement] = engagement if engagement
      i[:home_location] = home_location if home_location
      i[:work_location] = work_location if work_location
      i[:persona] = user_personas if user_personas.count > 0
      i[:time_slots] = time_slots if time_slots.count > 0
      i
    end

    def device_ids
      user_phone_details.collect { |x| x.deviceid }
    end

    def device_manufacturers
      user_phone_details.collect { |x| x.manufacturer }
    end

    def device_models
      user_phone_details.collect { |x| x.model }
    end

    def browsers
      []
    end

    def os
      []
    end

    def engagement
      1
    end

    def home_location
      if home_location_lat and home_location_lon
        [home_location_lat, home_location_lon].as_geopoint
      end
    end

    def work_location
      if work_location_lat and work_location_lon
        [work_location_lat, work_location_lon].as_geopoint
      end
    end

    def time_slots
      []
    end

  end
end

