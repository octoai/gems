require 'cequel'
require 'yaml'
require 'logger'

require 'octocore/version'
require 'octocore/utils'
require 'octocore/config'
require 'octocore/models'
require 'octocore/counter'

require 'octocore/trendable'
require 'octocore/baseline'
require 'octocore/trends'
require 'octocore/kldivergence'
require 'octocore/segment'
require 'octocore/scheduler'
require 'octocore/schedeuleable'
require 'octocore/helpers'
require 'octocore/kafka_bridge'
require 'octocore/stats'

# The main Octo module
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

  # Connect by reading configuration files from the given directory.
  #   In this case, all *.y*ml files would be read in
  #   Dir.glob order and merged into one unified config
  def self.connect_with_config_dir(config_dir)
    config = {}
    accepted_formats = Set.new(['.yaml', '.yml'])
    Dir[config_dir + '/*'].each do |file_obj|
      if File.file?(file_obj) and accepted_formats.include?File.extname(file_obj)
        config = self.true_load(config, file_obj, config_dir)
      elsif File.directory?(file_obj)
        Dir[file_obj + '/**/*.y*ml'].each do |file|
          config = self.true_load(config, file, config_dir)
        end
      end
    end
    # As a cleanup step, merge the values of key named "config"
    # with the global config hash
    configConfig = config.delete(:config)
    config = config.deep_merge(configConfig)
    # Now, good to merge the two
    self.connect config
  end

  # Loads the true config. The true config is the hierarchial config
  # @param [Hash] config The base config. Loaded config will be deep merged
  #   with this
  # @param [String] file The file from which config should be loaded
  # @param [String] config_fir The config dir in which the file is located
  # @return [Hash] The merged config hash
  def self.true_load(config, file, config_dir)
    _config = YAML.load_file file
    if _config
      $stdout.puts "Loading from Config file: #{ file }"
      # A little bit of hack here.
      # This hack makes sure that if we load config files from nestes
      # directories, the corresponding config is loaded in
      # hierarchy.
      # So, if the file is like /config/search/index.yml, the
      # key would be like [config[search[index]]]
      a = file.gsub(/(\/?#{config_dir}(\/)*(config\/)*|.yml)/, '').split('/')
      _true_config = a.reverse.inject(_config) { |r,e| { e => r } }
      config = config.deep_merge(_true_config.deep_symbolize_keys)
    end
    config
  end

  # Provides a unified interface to #connect_with_config_dir
  #   and #connect_with_config_file for convenience
  def self.connect_with(location)
    if File.directory?(location)
      self.connect_with_config_dir location
    elsif File.file?(location)
      self.connect_with_config_file location
    else
      puts "Invalid location #{ location }"
    end
  end


  # A low level method to connect using a configuration
  # @param [Hash] configuration The configuration hash
  def self._connect(configuration)

    load_config configuration

    self.logger.info('Octo booting up.')

    # Establish Cequel Connection
    connection = Cequel.connect(Octo.get_config(:cassandra))
    Cequel::Record.connection = connection

    # Establish connection to cache server
    default_cache = {
        host: '127.0.0.1', port: 6379
    }
    cache_config = Octo.get_config(:redis, default_cache)
    Cequel::Record.update_cache_config(*cache_config.values_at(:host, :port))

    # Establish connection to statsd server if required
    if configuration.has_key?(:statsd)
      statsd_config = configuration[:statsd]
      set_config :stats, Statsd.new(*statsd_config.values)
    end

    self.logger.info('I\'m connected now.')
    require 'octocore/callbacks'
    require 'octocore/search'

    self.logger.info('Setting callbacks.')
  end

  # Creates a logger for Octo
  def self.logger
    unless @logger
      @logger = Logger.new(Octo.get_config(:logfile, $stdout)).tap do |log|
        log.progname = name
      end
    end
    @logger
  end

end

