require 'octocore/baseline'
require 'octocore/counter'

module Octo

  module Trends

    include Octo::Counter::Helper

    DEFAULT_COUNT = 10

    # Define the columns needed for Trends
    def trendable
      key :type, :int
      key :ts, :timestamp
      key :rank, :int

      column :score, :float
      column :uid, :text

      generate_aggregators { |ts, method|
        trendtype = method_names_type_counter(method)
        aggregate_and_create trendtype, ts
      }

    end

    # Aggregates and creates trends for all the enterprises for a specific
    #   trend type at a specific timestamp
    # @param [Fixnum] oftype The type of trend to be calculated
    # @param [Time] ts The time at which trend needs to be calculated
    def aggregate_and_create(oftype, ts = Time.now.floor)
      Octo::Enterprise.each do |enterprise|
        calculate(enterprise.id, oftype, ts)
      end
    end

    # Override the aggregate! defined in counter class as the calculations
    #   for trending are a little different
    def aggregate!(ts = Time.now.floor)
      aggregate_and_create(Octo::Counter::TYPE_MINUTE, ts)
    end

    # Performs the actual trend calculation
    # @param [String] enterprise_id The enterprise ID for whom trend needs to be found
    # @param [Fixnum] trend_type The trend type to be calculates
    # @param [Time] ts The Timestamp at which trend needs to be calculated.
    def calculate(enterprise_id, trend_type, ts = Time.now.floor)
        args = {
          enterprise_id: enterprise_id,
          ts: ts,
          type: trend_type
        }

        klass = @trend_for.constantize
        hitsResult = klass.public_send(:where, args)
        trends = hitsResult.map { |h| counter2trend(h) }

        # group trends as per the time of their happening and rank them on their
        # score
        grouped_trends = trends.group_by { |x| x.ts }
        grouped_trends.each do |_ts, trendlist|
          sorted_trendlist = trendlist.sort_by { |x| x.score }
          sorted_trendlist.each_with_index do |trend, index|
            trend.rank = index
            trend.type = trend_type
            trend.save!
          end
        end
    end

    # Define the class for which trends shall be found
    def trend_for(klass)
      unless klass.constantize.ancestors.include?Cequel::Record
        raise ArgumentError, "Class #{ klass } does not represent a DB Model"
      else
        @trend_for = klass
      end
    end

    # Define the class which would be returned while fetching trending objects
    def trend_class(klass)
      @trend_class = klass
    end

    # Gets the trend of a type at a time
    # @param [String] enterprise_id The ID of enterprise for whom trend to fetch
    # @param [Fixnum] type The type of trend to fetch
    # @param [Hash] opts The options to be provided for finding trends
    def get_trending(enterprise_id, type, opts={})
      ts = opts.fetch(:ts, Time.now.floor)
      args = {
        enterprise_id: enterprise_id,
        ts: opts.fetch(:ts, Time.now.floor),
        type: type
      }
      res = where(args).limit(opts.fetch(:limit, DEFAULT_COUNT))
      enterprise = Octo::Enterprise.find_by_id(enterprise_id)
      if res.count == 0 and enterprise.fakedata?
        res = []
        if ts.class == Range
          ts_begin = ts.begin
          ts_end = ts.end
          ts_begin.to(ts_end, 1.day).each do |_ts|
            3.times do |rank|
              uid = @trend_class.constantize.send(:where, {enterprise_id: enterprise_id}).first(10).shuffle.pop.unique_id
              _args = args.merge( ts: _ts, rank: rank, score: rank+1, uid: uid )
              res << self.new(_args).save!
            end
          end
        elsif ts.class == Time
          3.times do |rank|
            uid = @trend_class.constantize.send(:where, {enterprise_id: enterprise_id}).first(10).shuffle.pop.unique_id
            _args = args.merge( rank: rank, score: rank+1, uid: uid )
            res << self.new(_args).save!
          end
        end
      end
      res.map do |r|
        clazz = @trend_class.constantize
        clazz.public_send(:recreate_from, r)
      end
    end

    private

    # Converts a couunter into a trend
    # @param [Object] counter A counter object. This object must belong
    #   to one of the counter types defined in models.
    # @return [Object] Returns a trend instance corresponding to the counter
    #   instance
    def counter2trend(counter)
      self.new({
        enterprise: counter.enterprise,
        score: score(counter.divergence),
        uid: counter.uid,
        ts: counter.ts
      })
    end

    # For now, just make sure divergence is absolute. This is responsible to
    #   score a counter on the basis of its divergence
    # @param [Float] divergence The divergence value
    # @return [Float] The score
    def score(divergence)
      return 0 if divergence.nil?
      divergence.abs
    end
  end
end
