require 'cequel'
require 'octocore/record'
require 'set'

module Octo

  # Stores the funnel for the enterprise
  class Funnel
    include Cequel::Record
    include Octo::Record

    belongs_to :enterprise, class_name: 'Octo::Enterprise'

    key :name, :text
    list :funnel, :text
    column :active, :boolean

    before_create :activate_funnel

    after_create :populate_with_fake_data

    # Activates a funnel
    def activate_funnel
      self.active = true
    end

    # Generates a new funnel from the pages provided
    def self.from_pages(pages, opts = {})
      funnel_length = pages.count
      return nil if funnel_length.zero?

      # Assume pages to be string URLs for the pages/products
      funnel = pages

      # Check if they are Octo::Product or Octo::Page instantces and handle
      if ::Set.new([Octo::Product, Octo::Page]).include?(pages[0].class)
        funnel = pages.collect { |p| p.routeurl }
        enterprise_id = pages[0].enterprise_id
      end

      # Create a new funnel
      self.new(
        enterprise_id: opts.fetch(:enterprise_id, enterprise_id),
        name: opts.fetch(:name),
        funnel: funnel
      ).save!
    end

    # Populates a newly created funnel with some fake data
    def populate_with_fake_data
      Octo::FunnelData.new(
        enterprise_id: self.enterprise_id,
        funnel_name: self.name,
        ts: Time.now.floor,
        value: fake_data(self.funnel.count)
      ).save!
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

