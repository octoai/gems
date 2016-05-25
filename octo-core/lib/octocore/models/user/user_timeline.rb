require 'cequel'
require 'ostruct'

module Octo
  class UserTimeline
    include Cequel::Record

    BROWSE_PRODUCT  = 0
    BROWSE_PAGE     = 1
    SEARCH          = 2
    SHARE           = 3
    ADD_TO_CART     = 4
    CHECKOUT        = 5
    APP_OPEN        = 6
    APP_CLOSE       = 7
    PAGE_RELOAD     = 8

    LOC_HOME        = 11
    LOC_OFFICE      = 12
    LOC_TRANSIT     = 13
    LOC_VACATION    = 14
    LOC_OOH         = 15
    LOC_OTHERS      = 16

    belongs_to :user, class_name: 'Octo::User'

    key :ts, :timestamp

    column :type, :int
    column :title, :text
    column :location_type, :int
    column :insight, :text
    column :details, :text

    timestamps

    def self.fakedata(user, n = rand(7..20))
      Array.new(3*n) do |i|
        i+1
      end.shuffle.sample(n).sort.reverse.collect do |i|
        args = {
          user: user,
          ts: i.minutes.ago,
          type: rand(0..8),
          title: 'Product Name',
          location_type: rand(11..16),
          insight: 'some valueable insight',
          details: 'other details here'
        }
        self.new(args).save!
      end
    end

    def location_text(location_type)
      case location_type
      when LOC_HOME
        'Home'
      when LOC_OFFICE
        'Office'
      when LOC_TRANSIT
        'In Transit'
      when LOC_VACATION
        'While Vacation'
      when LOC_OOH
        'Out of Home City'
      when LOC_OTHERS
        'Other Location'
      end
    end

    def type_text(activity_type)
      case activity_type
      when BROWSE_PRODUCT
        'Browsed for Product'
      when BROWSE_PAGE
        'Browsed for Page'
      when SEARCH
        'Searched'
      when SHARE
        'Shared'
      when ADD_TO_CART
        'Added to Cart'
      when CHECKOUT
        'Performed Checkout'
      when APP_OPEN
        'Opened App'
      when APP_CLOSE
        'Closed App'
      when PAGE_RELOAD
        'Reloaded Page'
      end
    end

    def human_readable
      args = {
        user: self.user,
        ts: self.ts,
        type: type_text(self.type),
        type_raw: self.type,
        title: self.title,
        location: location_text(self.location_type),
        location_raw: self.location_type,
        insight: self.insight,
        details: self.details
      }
      OpenStruct.new(args)
    end

  end
end

