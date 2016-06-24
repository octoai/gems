require 'ruby-kafka'

module Octo
  # The bridge between Kafka and ruby
  class KafkaBridge

    # These are hard wired
    CLIENT_ID = ENV['KAFKA_CLIENT_ID']
    TOPIC     = ENV['KAFKA_TOPIC']

    MAX_BUFFER_SIZE = 20_000

    MAX_QUEUE_SIZE = 10_000

    DELIVERY_INTERVAL = 1

    # Changes as per environment
    BROKERS   = ENV['KAFKA_BROKERS'].try(:split, ',')

    def initialize(opts = {})
      opts.deep_symbolize_keys!
      @kafka = ::Kafka.new(seed_brokers: opts.fetch(:brokers, BROKERS),
                         client_id: opts.fetch(:client_id, CLIENT_ID)
      )
      @producer = @kafka.async_producer(
        max_buffer_size: opts.fetch(:max_buffer_size, MAX_BUFFER_SIZE),
        max_queue_size: opts.fetch(:max_queue_size, MAX_QUEUE_SIZE),
        delivery_interval: opts.fetch(:delivery_interval, DELIVERY_INTERVAL),
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
      begin
        @producer.produce(JSON.dump(message), topic: @topic)
      rescue Kafka::BufferOverflow
        Octo.logger.error 'Buffer Overflow. Sleeping for 1s'
        sleep 1
        retry
      end
    end

  end
end
