require 'statsd-ruby'

module Octo

  # Instrumentation and Statistical module
  module Stats

    # Instrument a block identified by its name
    # @param [Symbol] name The name by which this would be identified
    def instrument(name)
      if stats
        stats.time(name.to_s, &Proc.new)
      else
        yield
      end
    end

    # Get stats instance
    def stats
      if statd_config
        @statsd = Statsd.new(*statd_config.values) unless @statsd
        @statsd
      end
    end

    private

    # Get stats config from Octo
    def statd_config
      Octo.get_config :statsd
    end
  end
end