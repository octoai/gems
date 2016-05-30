require 'octocore/counter/helpers'
require 'descriptive_statistics'

module Octo

  # The baseline module. This module has methods that support
  #   a baseline structure.
  module Baseline

    include Octo::Counter::Helper

    # Define the past duration to look for while calculating
    # baseline. This must be in days
    MAX_DURATION = 7

    # Defines the column needed for a baseline
    def baselineable
      key :type, :int
      key :ts, :timestamp
      key :uid, :text

      column :val, :float

      # Generate the aggregator methods
      generate_aggregators { |ts, method|
        type = method_names_type_counter(method)
        aggregate type, ts
      }
    end

    # Defines the class for whom the baseline is applicable
    def baseline_for(klass)
      @baseline_for = klass
    end

    # Finds baseline value of an object
    # @param [Fixnum] baseline_type One of the valid Baseline Types defined
    # @param [Object] obj The object for whom baseline value is to be found
    # @param [Time] ts The timestamp at which baseline is to be found
    def get_baseline_value(baseline_type, obj, ts = Time.now.ceil)
      unless Octo::Counter.constants.include?baseline_type
        raise ArgumentError, 'No such baseline defined'
      end

      args = {
          ts: ts,
          type: Octo::Counter.const_get(baseline_type),
          uid: obj.unique_id,
          enterprise_id: obj.enterprise.id
      }
      bl = get_cached(args)
      if bl
        bl.val
      else
        0.01
      end
    end

    # Does an aggregation of type for a timestamp
    # @param [Fixnum] type The counter type for which aggregation
    #   has to be done
    # @param [Time] ts The time at which aggregation should happen
    def aggregate(type, ts)
      Octo::Enterprise.each do |enterprise|
        aggregate_baseline enterprise.id, type, ts
      end
    end


    # Aggregates the baseline for a minute
    def aggregate_baseline(enterprise_id, type, ts = Time.now.floor)
      clazz = @baseline_for.constantize
      _ts = ts
      start_calc_time = (_ts.to_datetime - MAX_DURATION.day).to_time
      last_n_days_interval = start_calc_time.ceil.to(_ts, 24.hour)
      last_n_days_interval.each do |hist|
        args = {
            ts: hist,
            type: type,
            enterprise_id: enterprise_id
        }
        counters = @baseline_for.constantize.send(:where, args)
        baseline = baseline_from_counters(counters)
        store_baseline enterprise_id, type, hist, baseline
      end
    end

    private

    # Stores the baseline for an enterprise, and type
    # @param [String] enterprise_id The enterprise ID of enterprise
    # @param [Fixnum] type The Counter type as baseline type
    # @param [Time] ts The time stamp of storage
    # @param [Hash{String => Float}] baseline A hash representing baseline
    def store_baseline(enterprise_id, type, ts, baseline)
      return if baseline.nil? or baseline.empty?
      baseline.each do |uid, val|
        self.new({
                     enterprise_id: enterprise_id,
                     type: type,
                     ts: ts,
                     uid: uid,
                     val: val
                 }).save!
      end
    end

    # Calculates the baseline from counters
    def baseline_from_counters(counters)
      baseline = {}
      uid_groups = counters.group_by { |x| x.uid }
      uid_groups.each do |uid, counts|
        baseline[uid] = score_counts(counts)
      end
      baseline
    end

    # Calculates the baseline score from an array of scores
    # @param [Array<Float>] counts The counts array
    # @return [Float] The baseline score for counters
    def score_counts(counts)
      if counts.count > 0
        _num = counts.map { |x| x.obp }
        _num.percentile(90)
      else
        0.01
      end
    end

  end
end
