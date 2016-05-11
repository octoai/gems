require 'cequel'
require 'octocore/record'
require 'set'

module Octo

  # Stores the funnel for the enterprise
  class Funnel
    include Cequel::Record
    include Octo::Record

    belongs_to :enterprise, class_name: 'Octo::Enterprise'

    key :name_slug, :text
    list :funnel, :text

    column :name, :text
    column :active, :boolean

    before_create :create_name_slug, :activate_funnel

    after_create :populate_with_fake_data

    # Creates name slug
    def create_name_slug
      self.name_slug = self.name.to_slug
    end

    # Activates a funnel
    def activate_funnel
      self.active = true
    end

    # Generates a new funnel from the pages provided
    # @param [Array] pages The pages array. This array could contain instances
    #   of either String, Octo::Product or Octo::Page.
    #   If string, it will be assumed that these are routeurls for pages or
    #   products.
    #   If the class is explicitly specified, it will be used.
    # @param [Hash] opts The options for creating funnel
    # @option opts [String] :name The name of the funnel
    # @option opts [String] :enterprise_id The enterprise ID for whom funnel is
    #   being created
    # @return [Octo::Funnel] The funnel created
    def self.from_pages(pages, opts = {})
      funnel_length = pages.count
      return nil if funnel_length.zero?

      funnel = Array.new
      enterprise_id = opts.fetch(:enterprise_id, nil)

      # Check if they are Octo::Product or Octo::Page instantces and handle
      if ::Set.new([Octo::Product, Octo::Page]).include?(pages[0].class)
        funnel = pages.collect { |p| p.routeurl }
        enterprise_id = pages[0].enterprise_id
      elsif pages[0].class == String
        funnel = pages
      end

      # Create a new funnel
      self.new(
        enterprise_id: enterprise_id,
        name: opts.fetch(:name),
        funnel: funnel
      ).save!
    end

    # Populates a newly created funnel with some fake data
    # @param [Fixnum] days The number of days for which data to be faked
    def populate_with_fake_data(interval_days = 7)
      today = Time.now.beginning_of_day
      (today - interval_days.days).to(today, 24.hour).each do |ts|
        Octo::FunnelData.new(
          enterprise_id: self.enterprise_id,
          funnel_slug: self.name_slug,
          ts: Time.now.floor,
          value: fake_data(self.funnel.count)
        ).save!
      end
    end

    # Returns all the data for a funnel
    # @return [Octo::FunnelData] The Octo funnel data
    def data
      Octo::FunnelData.find_by_enterprise_id_and_funnel_slug(
        enterprise_id: self.enterprise_id,
        funnel_slug: self.name_slug
      )
    end

    private

    # Generates fake data for funnel
    # @param [Fixnum] n The length of funnel
    # @return [Array] An array containing the funnel value
    def fake_data(n)
      fun = Array.new(n)
      max_dropoff = 100/n
      n.times do |i|
        if i == 0
          fun[i] = 100.0
        else
          fun[i] = fun[i-1] - rand(1..max_dropoff)
          if fun[i] < 0
            fun[i] = rand(0...fun[i].abs)
          end
        end
      end
      fun
    end

  end
end

