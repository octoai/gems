require 'octocore/kldivergence'
require 'octocore/counter'

module Octo

  module Trendable

    include Octo::KLDivergence

    # Define the columns necessary for a trendable model
    def trendables
      column :divergence, :float
      column :obp, :float
    end

    # Define the baseline class for this trend
    def baseline(klass)
      @baseline_klass = klass
    end

    # Define the class for trends
    def trends_class(klass)
      @trends_klass = klass
    end

    # Aggregates and attempts to store it into the database. This would only
    #   work if the class that extends Octo::Counter includes from
    #   Cequel::Record
    def aggregate!(ts = Time.now.floor)
      unless self.ancestors.include?Cequel::Record
        raise NoMethodError, 'aggregate! not defined for this counter'
      end

      aggr = aggregate(ts)
      sum = aggregate_sum(aggr)
      aggr.each do |_ts, counterVals|
        counterVals.each do |obj, count|
          counter = self.new
          counter.enterprise = obj.enterprise
          counter.uid = obj.unique_id
          counter.count = count
          counter.type = Octo::Counter::TYPE_MINUTE
          counter.ts = _ts
          totalCount = sum[_ts][obj.enterprise_id.to_s].to_f
          counter.obp = (count * 1.0)/totalCount

          baseline_value = get_baseline_value(:TYPE_MINUTE, obj)
          counter.divergence = kl_divergence(counter.obp,
                                             baseline_value)
          counter.save!
        end
      end
      call_completion_hook(Octo::Counter::TYPE_MINUTE, ts)
    end

    private

    # Aggregates to find the sum of all counters for an enterprise
    #   at a time
    # @param [Hash] aggr The aggregated hash
    # @return [Hash] The summed up hash
    def aggregate_sum(aggr)
      sum = {}
      aggr.each do |ts, counterVals|
        sum[ts] = {} unless sum.has_key?ts
        counterVals.each do |obj, count|
          if obj.respond_to?(:enterprise_id)
            eid = obj.public_send(:enterprise_id).to_s
            sum[ts][eid] = sum[ts].fetch(eid, 0) + count
          end
        end
      end
      sum
    end

    # Get the baseline value for an object.
    # @param [Fixnum] baseline_type The type of baseline to fetch
    # @param [Object] object The object for which baseline is to
    #   be fetched
    def get_baseline_value(baseline_type, object)
      clazz = @baseline_klass.constantize
      clazz.public_send(:get_baseline_value, baseline_type, object)
    end


  end

end
