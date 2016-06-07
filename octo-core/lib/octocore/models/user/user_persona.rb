require 'cequel'

module Octo

  class UserPersona

    include Cequel::Record

    HIGH_ENGAGED = 0
    MEDIUM_ENGAGED = 1
    LOW_ENGAGED = 2
    DEAD = 3

    belongs_to :user, class_name: 'Octo::User'
    key :ts, :timestamp

    map :categories, :text, :float
    map :tags, :text, :float
    map :trending, :text, :float
    column :engagement, :float

    def engaged_text
      _engaged_text self.engagement
    end

    def self.engaged_text(val)
      _engaged_text val
    end

    def self.fakedata(user, ts)
      args = {
        user_enterprise_id: user.enterprise.id,
        user_id: user.id,
        ts: ts
      }
      res = self.where(args)
      if res.count < 1
        categories = Hash[Octo::Category.first(rand(1..Octo::Category.count)).collect do |x|
          [x.cat_text, rand(20..200)]
        end]
        tags = Hash[Octo::Tag.first(rand(1..Octo::Tag.count)).collect do |x|
          [x.tag_text, rand(20.200)]
        end]
        trending = ['trending', 'non trending'].collect do |x|
          [x, rand(10..50)]
        end
        args = {
          user: user,
          categories: categories,
          tags: tags,
          trending: trending,
          engagement: rand(0..3)
        }
        res = []
        if ts.class == Range
          start_ts = ts.begin.beginning_of_day
          end_ts = ts.end.end_of_day
          start_ts.to(end_ts, 1.day).each do |_ts|
            _args = args.merge({ ts: _ts})
            res << self.new(_args).save!
          end
        elsif ts.class == Time
          _args = args.merge({ts: ts})
          res << self.new(_args).save!
        end
      end
      self.aggregate res
    end

    def self.aggregate(res)
      personas = [:categories, :tags, :trending]
      personas.inject({}) do |result, p|
        result[p] = res.collect do |r|
          r.send(p)
        end.inject({}) do |sum, values|
          values.each do |k,v|
            sum[k] = sum.fetch(k, 0) + v
            sum
          end
        end
        result
      end
    end

    private

    def _engaged_text(val)
      case val
      when HIGH_ENGAGED
        'Highly Engaged'
      when MEDIUM_ENGAGED
        'Moderately Engaged'
      when LOW_ENGAGED
        'Low Engagement'
      when DEAD
        'Slipping Out'
      end
    end

  end
end
