module Octo
  # The bridge between Kafka and ruby
  class KafkaBridge

    # These are hard wired
    CLIENT_ID = ENV['KAFKA_CLIENT_ID']
    TOPIC     = ENV['KAFKA_TOPIC']

    # Changes as per environment
    BROKERS   = ENV['KAFKA_BROKERS'].try(:split, ',')

    def initialize(opts = {})
      opts.deep_symbolize_keys!
      @kafka = Kafka.new(seed_brokers: opts.fetch(:brokers, BROKERS),
                         client_id: opts.fetch(:client_id, CLIENT_ID)
      )
      @producer = @kafka.async_producer(
          # Trigger a delivery once 100 messages have been buffered.
          delivery_threshold: 100,

          # to avoid any potential Kafka::BufferOverflow error
          max_buffer_size: 200,

          # Trigger a delivery every 3 seconds.
          delivery_interval: 3,
      )
      if opts.has_key?(:topic)
        @topic = opts[:topic]
      else
        @topic = TOPIC
      end
    end

    def push(params)
      create_message params
    end

    def teardown
      @producer.shutdown
    end

    private

    # Creates a new message.
    # @param [Hash] message The message hash to be produced
    def create_message(message)
      @producer.produce(JSON.dump(message), topic: @topic)
    end

  end
end
