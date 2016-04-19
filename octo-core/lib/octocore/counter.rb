require 'octocore/counter/helpers'

module Octo
  module Counter
    include Octo::Counter::Helper

    INDEX_KEY_PREFIX = :CounterIndex
    COUNTER_KEY_PREFIX = :Counter

    SEPARATOR = '_'

    # Define the different types of counters here. As a design decision
    # you MUST ALWAYS keep the counters that can be created from
    # subcounters in multiples. So for instance, you can not create
    # a counter of type TYPE_MINUTE_36 from a counter of type TYPE_MINUTE_15.
    # If you have to create a counter of type TYPE_MINUTE_36, consider
    # creating subcounters like TYPE_MINUTE_9 and TYPE_MINUTE_4. Derive
    # TYPE_MINUTE_9 from TYPE_MINUTE_4 and TYPE_MINUTE_4 from TYPE_MINUTE_1
    TYPE_MINUTE     = 0
    TYPE_MINUTE_30  = 1
    TYPE_HOUR       = 2
    TYPE_HOUR_3     = 3
    TYPE_HOUR_6     = 4
    TYPE_HOUR_12    = 5
    TYPE_DAY        = 6
    TYPE_DAY_3      = 7
    TYPE_DAY_6      = 8
    TYPE_WEEK       = 9


    # Define the columns necessary for counter model
    def countables
      key :type, :int
      key :ts, :timestamp
      key :uid, :text

      column :count, :bigint

      generate_aggregators { |ts, method|
        totype = method_names_type_counter(method)
        fromtype = get_fromtype_for_totype(totype)
        aggregate_and_create(fromtype, totype, ts)
      }
    end

    # Increments the counter for a model.
    # @param [Object] obj The model instance for whom counter would be
    #   incremented
    def increment_for(obj)
      # decide the time of event asap
      ts = Time.now.ceil.to_i

      if obj.class.ancestors.include?Cequel::Record
        args = obj.key_attributes.collect { |k,v|  v.to_s }
        cache_key = generate_key(ts, obj.class.name, *args)

        val = Cequel::Record.redis.get(cache_key)
        if val.nil?
          val = 1
        else
          val = val.to_i + 1
        end

        ttl = (time_window + 1) * 60

        # Update a sharded counter
        Cequel::Record.redis.setex(cache_key, ttl, val)

        # Optionally, update the index
        index_key = generate_index_key(ts, obj.class.name, *args)
        index_present = Cequel::Record.redis.get(index_key).try(:to_i)
        if index_present != 1
          Cequel::Record.redis.setex(index_key, ttl, 1)
        end
      end

    end

    def aggregate_and_create(from_type, to_type, ts = Time.now.ceil)
      duration = get_duration_for_counter_type(to_type, ts)
      aggr = local_count(duration, from_type)
      sum = local_counter_sum(aggr)
      update_counters(aggr, sum, to_type, ts)
      # Post Update Hooks should go here
      call_completion_hook(to_type, ts)
    end

    def call_completion_hook(type, ts)
      # If this counter type has a corresponding trends_klass
      # it means that the trend for it must be calculated.
      # So, schedule the trend calculation right after this
      # is finished
      if self.instance_variables.include?(:@trends_klass)
        klass = self.instance_variable_get(:@trends_klass).constantize
        # make sure it responds to the aggregation method
        if klass.respond_to?(:aggregate_and_create)
          klass.send(:aggregate_and_create, type, ts)
        end
      end
    end

    def update_counters(aggr, sum, type, ts)
      aggr.each do |enterprise_id, uidCounters|
        uidCounters.each do |uid, count|
          counter = self.new({
                                 enterprise_id: enterprise_id,
                                 uid: uid,
                                 count: count,
                                 type: type,
                                 ts: ts
                             })
          if counter.respond_to?(:obp)
            counter.obp = count.to_f/sum[enterprise_id]
          end
          counter.save!
        end
      end
    end

    # Does the counting from DB. Unlike the other counter that uses Redis. Hence
    #   the name local_count
    # @param [Time] duration A time/time range object
    # @param [Fixnum] type The type of counter to look for
    def local_count(duration, type)
      aggr = {}
      Octo::Enterprise.each do |enterprise|
        args = {
            enterprise_id: enterprise.id,
            ts: duration,
            type: type
        }
        aggr[enterprise.id.to_s] = {} unless aggr.has_key?(enterprise.id.to_s)
        results = where(args)
        results_group = results.group_by { |x| x.uid }
        results_group.each do |uid, counters|
          _sum = counters.inject(0) do |sum, counter|
            sum + counter.count
          end
          aggr[enterprise.id.to_s][uid] = _sum
        end
      end
      aggr
    end

    def local_counter_sum(aggr)
      sum = {}
      aggr.each do |enterprise_id, uidCounters|
        _sum = uidCounters.values.inject(0) do |s, count|
          s + count
        end
        sum[enterprise_id] = _sum
      end
      sum
    end

    # Aggregates all the counters available. Aggregation of only time specific
    #   events can be done by passing the `ts` parameter.
    # @param [Time] ts The time at which aggregation has to be done.
    # @return [Hash{Fixnum => Hash{ Obj => Fixnum }}] The counts of each object
    def aggregate(ts = Time.now.floor)
      ts = ts.to_i
      aggr = {}
      # Find all counters from the index
      index_key = generate_index_key(ts, '*')
      counters = Cequel::Record.redis.keys(index_key)
      counters.each do |cnt|
        _tmp = cnt.split(SEPARATOR)
        _ts = _tmp[2].to_i
        aggr[_ts] = {} unless aggr.has_key?(_ts)

        clazz = _tmp[3]
        _clazz = clazz.constantize

        _attrs = _tmp[4.._tmp.length]

        args = {}
        _clazz.key_column_names.each_with_index do |k, i|
          args[k] = _attrs[i]
        end

        obj = _clazz.public_send(:get_cached, args)

        # construct the keys for all counters matching this patter
        _attrs << '*'
        counters_search_key = generate_key_prefix(_ts, clazz, _attrs)
        counter_keys = Cequel::Record.redis.keys(counters_search_key)
        counter_keys.each do |c_key|
          val = Cequel::Record.redis.get(c_key)
          if val
            aggr[_ts][obj] = aggr[_ts].fetch(obj, 0) + val.to_i
          else
            aggr[_ts][obj] = aggr[_ts].fetch(obj, 0) + 1
          end
        end
      end
      aggr

    end

    # Aggregates and attempts to store it into the database. This would only
    #   work if the class that extends Octo::Counter includes from
    #   Cequel::Record
    def aggregate!(ts = Time.now.floor)
      unless self.ancestors.include?Cequel::Record
        raise NoMethodError, "aggregate! not defined for this counter"
      end

      aggr = aggregate(ts)
      aggr.each do |_ts, counterVals|
        counterVals.each do |obj, count|
          args = gen_args_for_instance obj, count, _ts, TYPE_MINUTE
          counter = self.new args
          counter.save!
        end
      end
      call_completion_hook(TYPE_MINUTE, ts)
    end

    private

    def gen_args_for_instance(obj, count, ts, type)
      {
          enterprise: obj.enterprise,
          uid: obj.unique_id,
          count: count,
          type: type,
          ts: ts
      }
    end

    def generate_key(ts, *args)
      args << rand(counters)
      [COUNTER_KEY_PREFIX, ts, *args].join(SEPARATOR)
    end

    def generate_key_prefix(ts, *args)
      [COUNTER_KEY_PREFIX, ts, *args].join(SEPARATOR)
    end

    def generate_index_key(ts, *args)
      [INDEX_KEY_PREFIX, self.name, ts, *args].join(SEPARATOR)
    end

    def counters
      if self.constants.include?(:COUNTERS)
        self.const_get(:COUNTERS)
      else
        30
      end
    end

    def time_window
      if self.constants.include?(:TIME_WINDOW)
        self.const_get(:TIME_WINDOW)
      else
        1
      end
    end

  end
end
