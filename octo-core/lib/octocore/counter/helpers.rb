module Octo
  module Counter
    module Helper


      #The prefix to use when converting a type constant into an
      #aggregator method name
      METHOD_PREFIX = 'aggregate'


      # Defined the method names for the type counters.
      def type_counters_method_names(type = nil)
        if type.nil?
          get_typecounters.map do |typ|
            [METHOD_PREFIX, typ.to_s.downcase].join('_')
          end
        else
          [METHOD_PREFIX, type.to_s.downcase].join('_')
        end
      end

      # Get all the type counters i.e. TYPE_MINUTE_30 etc from
      #   Counter class.
      # @return [Array] Array of all the constants that define a counter type
      def get_typecounters
        max = max_type
        Counter.constants.select do |x|
          if x.to_s.start_with?('TYPE')
            Counter.const_get(x) <= max
          else
            false
          end
        end
      end

      # Define the max granularity that should exist
      def max_type(type = nil)
        if @max_type
          @max_type
        else
          if type
            @max_type = type
          else
            @max_type = 9
          end
        end
        @max_type
      end

      # Coverts the method name to the constant type
      # @param [String] method_name The method name to convert into constant
      # @return [Symbol] The constant
      def method_names_type_counter(method_name)
        prefix, *counterType = method_name.to_s.split('_')
        if prefix == METHOD_PREFIX
          cnst = counterType.join('_').upcase.to_sym
          string_to_const_val(cnst)
        end
      end

      # Converts a string (which may represent a counter constant) into its
      #   corresponding constant
      # @param [String] cnst The string which may represent a constant
      # @return [Fixnum] The constant value; iff the string represent a constant.
      #   Nil otherwise
      def string_to_const_val(cnst)
        index = Counter.constants.index(cnst)
        if index
          Counter.const_get(cnst)
        end
      end

      # Generates a fromtype for a totype. This defines the relation
      #  of aggregation needed for the counters.
      def get_fromtype_for_totype(totype)
        case totype
          when TYPE_MINUTE_30
            TYPE_MINUTE
          when TYPE_HOUR
            TYPE_MINUTE_30
          when TYPE_HOUR_3
            TYPE_HOUR
          when TYPE_HOUR_6
            TYPE_HOUR_3
          when TYPE_HOUR_12
            TYPE_HOUR_6
          when TYPE_DAY
            TYPE_HOUR_6
          when TYPE_DAY_3
            TYPE_DAY
          when TYPE_DAY_6
            TYPE_DAY_3
          when TYPE_WEEK
            TYPE_DAY_3
          else
            TYPE_WEEK
        end
      end

      # Gets the duration for a particular counter type. This helps in
      #    aggregation.
      # @param [Fixnum] type The counter type
      # @param [Time] ts The time at wich duration needs to be passed
      # @return [Time] The time or time range for the given specs
      def get_duration_for_counter_type(type, ts=Time.now.ceil)
        start_time, step =  case type
                              when TYPE_MINUTE
                                [2.minute.ago, 1.minute]
                              when TYPE_MINUTE_30
                                [30.minute.ago, 1.minute]
                              when TYPE_HOUR
                                [1.hour.ago, 30.minute]
                              when TYPE_HOUR_3
                                [3.hour.ago, 1.hour]
                              when TYPE_HOUR_6
                                [6.hour.ago, 3.hour]
                              when TYPE_HOUR_12
                                [12.hour.ago, 6.hour]
                              when TYPE_DAY
                                [1.day.ago, 6.hour]
                              when TYPE_DAY_3
                                [3.day.ago, 1.day]
                              when TYPE_DAY_6
                                [6.day.ago, 3.day]
                              when TYPE_WEEK
                                [1.week.ago, 1.week]
                            end
        start_time.ceil.to(ts, step)
      end

      # Returns the mapping for counters as text
      # @return [Hash]
      def self.counter_text
        {
          TYPE_MINUTE => 'Near Real Time',
          TYPE_MINUTE_30 => '30 Minute',
          TYPE_HOUR => 'Hourly',
          TYPE_HOUR_3 => '3 Hourly',
          TYPE_HOUR_6 => '6 Hourly',
          TYPE_HOUR_12 => '12 Hourly',
          TYPE_DAY => 'Daily',
          TYPE_DAY_3 => '3 Days',
          TYPE_DAY_6 => '6 Days',
          TYPE_WEEK => 'Weekly'
        }
      end

      # Generate aggregator methods for a class. You can pass
      # your own block to generator for all custom needs.
      # Check out the implementation at Octo::Counter#countables
      # or Octo::Trends#trendable
      # @param [Block] block The block to be evaluated while executing
      #   the method
      def generate_aggregators(&block)
        @stored_block = block
        type_counters_method_names.each do |method_name|
          singleton_class.module_eval(<<-RUBY, __FILE__, __LINE__+1)
            def #{ method_name } (ts=Time.now.floor)
              bl = self.instance_variable_get(:@stored_block)
              instance_exec(ts, __method__, &bl) if bl
            end
          RUBY
        end
      end

    end
  end
end
