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

    settings index: { number_of_shards: 1 } do
      mappings dynamic: 'false' do
        indexes :enterpriseid, analyzer: 'keyword', index_options: 'offsets'
        indexes :id, type: :integer
        indexes :last_login, type: :date
        indexes :curr_state, type: :string
        indexes :city, type: :string
        indexes :state, type: :string
        indexes :country, type: :string
        indexes :os, type: :nested
        indexes :browser, type: :nested
        indexes :engagement, type: :integer
        indexes :home_location, type: :geo_point
        indexes :work_location, type: :geo_point
        indexes :persona, type: :nested
        indexes :time_slots, type: :nested
      end
    end


    # Returns the data for indexing purposess.
    # @return [Hash] The user object's fields and values represented as a hash
    #   for indexing purposes
    #
    def as_indexed_json(options = {})
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

    # Gets the list of device IDs for the user
    # @return [Array<String>] Device IDs for the user
    #
    def device_ids
      user_phone_details.collect { |x| x.deviceid }
    end

    # Gets the list of device manufacturers for the set of devices that user
    #   has
    # @return [Array<String>] The array of device manufacturers
    #
    def device_manufacturers
      user_phone_details.collect { |x| x.manufacturer }
    end

    # Gets the list of device models for the user
    # @return [Array<String>] The array of device models for the user
    #
    def device_models
      user_phone_details.collect { |x| x.model }
    end

    # Gets the browsers for the user
    # @return [Array<String>] Array of browsers
    #
    def browsers
      []
    end

    # Gets the list of OSs for the user
    # @return [Array<String>] List of OSs of the user
    #
    def os
      []
    end

    # Gets the engagement class of the user
    # @return [Fixnum] The engagement class of user. Defaults to 1
    #
    def engagement
      1
    end

    # Returns the home location of user as a geopoint data type
    # @return [Hash] The home location of user
    #
    def home_location
      if home_location_lat and home_location_lon
        [home_location_lat, home_location_lon].as_geopoint
      end
    end

    # Gets the work location of user as a geopoint data type
    # @return [Hash] The work location of user
    #
    def work_location
      if work_location_lat and work_location_lon
        [work_location_lat, work_location_lon].as_geopoint
      end
    end

    # Gets the time slots for which the user is active
    # @return [Array<Range>] The time slots of user
    def time_slots
      []
    end

  end
end

