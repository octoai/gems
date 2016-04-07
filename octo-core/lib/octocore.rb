require 'cequel'
require 'yaml'

require 'octocore/models'
require 'octocore/version'
require 'octocore/counter'
require 'octocore/utils'
require 'octocore/trendable'
require 'octocore/baseline'
require 'octocore/trends'
require 'octocore/kldivergence'
require 'octocore/scheduler'
require 'octocore/schedeuleable'


module Octo

  # Connect using the provided configuration. If you want to extend Octo's connect
  #   method you can override this method with your own. Just make sure to make
  #   a call to self._connect(configuration) so that Octo also connects
  # @param [Hash] configuration The configuration hash
  def self.connect(configuration)
    self._connect(configuration)
  end

  # Connect by reading configuration from the provided file
  # @param [String] config_file Location of the YAML config file
  def self.connect_with_config_file(config_file)
    config = YAML.load_file(config_file).deep_symbolize_keys
    self.connect(config)
  end


  def self._connect(configuration)
    # Establish Cequel Connection
    connection = Cequel.connect(configuration)
    Cequel::Record.connection = connection

    # Establish connection to cache server
    default_cache = {
        host: '127.0.0.1', port: 6379
    }
    cache_config = configuration.fetch(:redis, default_cache)
    Cequel::Record.update_cache_config(*cache_config.values_at(:host, :port))
  end

end
