require 'cequel'

module Octo
  class UserTimeline
    include Cequel::Record

    BROWSE_PRODUCT  = 0
    BROWSE_PAGE     = 1
    SEARCH          = 2
    SHARE           = 3
    ADD_TO_CART     = 4
    CHECKOUT        = 5

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

    def self.fakedata(user, n = rand(4..9))
      Array.new(3*n) do |i|
        i+1
      end.shuffle.sample(n).sort.reverse.collect do |i|
        args = {
          user: user,
          ts: i.minutes.ago,
          type: rand(0..5),
          title: 'title',
          location_type: rand(11..16),
          insight: 'some valueable insight',
          details: 'other details here'
        }
        self.new(args).save!
      end
    end

  end
end

