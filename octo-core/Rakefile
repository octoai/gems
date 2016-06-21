require 'cequel'
require 'yaml'
require 'redis'
require 'rspec/core/rake_task'

require 'octocore/helpers/kong_helper'
require 'octocore/config'

RSpec::Core::RakeTask.new('spec')

task :environment do
  config_dir = 'lib/octocore/config'
  config = {}
  Dir['**{,/*/**}/*.yml'].each do |file|
    _config = YAML.load_file(file)
    if _config
      puts "loading from file: #{ file }"
      config.merge!(_config.deep_symbolize_keys)
    end
  end
  Octo.load_config config
  connection = Cequel.connect(Octo.get_config(:cassandra))
  Cequel::Record.connection = connection
end

# Load default tasks from Cequel
spec = Gem::Specification.find_by_name 'cequel'
load "#{spec.gem_dir}/lib/cequel/record/tasks.rb"

# Remove those tasks from cequel which we shall override
%w(cequel:init cequel:migrate cequel:reset).each do |t|
  Rake.application.instance_variable_get('@tasks').delete(t)
end

# Overriding rake actions
namespace :octo do

  desc 'Create keyspace and tables for all defined models'
  task :init => %w(cequel:keyspace:create octo:migrate)

  desc 'Drop keyspace if exists, then create and migrate'
  task :reset => :environment do
    kong_delete
    clear_cache
    if Cequel::Record.connection.schema.exists?
      task('cequel:keyspace:drop').invoke
    end
    task('cequel:keyspace:create').invoke
    migrate
  end

  desc "Synchronize all models defined in `lib/octocore/models' with Cassandra " \
       "database schema"
  task :migrate => :environment do
    migrate
  end
end

# Delete Kong Consumers and Apis
def kong_delete
  Octo::Helpers::KongBridge.delete_all
  puts 'Kong Cleaned'
end

# Clear Cache
def clear_cache
  default_cache = {
    host: '127.0.0.1', port: 6379
  }
  redis = Redis.new(default_cache.merge(driver: :hiredis))
  redis.flushall
  puts 'Cache Cleaned'
end

def migrate
  watch_stack = ActiveSupport::Dependencies::WatchStack.new

  migration_table_names = Set[]

  classes = Set[]

  project_root = Dir.pwd
  models_dir_path = "#{File.expand_path('lib/octocore/models', project_root)}/"
  model_files = Dir.glob(File.join(models_dir_path, '**', '*.rb'))

  model_files.sort.each do |file|
    watch_namespaces = ["Object"]
    model_file_name = file.sub(/^#{Regexp.escape(models_dir_path)}/, "")
    dirname = File.dirname(model_file_name)
    watch_namespaces << dirname.classify unless dirname == "."
    watch_stack.watch_namespaces(watch_namespaces)

    require_dependency(file)

    new_constants = watch_stack.new_constants
    if new_constants.empty?
      _new = model_file_name.sub(/\.rb$/, "")
      if Octo.constants.include?_new.classify.to_sym
        new_constants << "Octo"
      else
        new_constants << "Octo"
        #new_constants << _new.classify
      end
    end

    new_constants.each do |class_name|
      begin
        clazz = class_name.constantize
      rescue LoadError, RuntimeError, NameError => e
        puts e
      else
        if clazz.is_a?(Class)
          if clazz.ancestors.include?(Cequel::Record) &&
              !migration_table_names.include?(clazz.table_name.to_sym)
            clazz.synchronize_schema
            migration_table_names << clazz.table_name.to_sym
            puts "** Synchronized schema for #{class_name}"
          end
        elsif clazz.is_a?(Module)
          method_name = :constants
          clazzes = clazz.public_send(method_name) if clazz.respond_to? method_name
          clazzes.each do |_clazz|
            _cls = clazz.const_get(_clazz)
            if _cls.is_a?(Class) and !classes.include?_cls
              if _cls.ancestors.include?(Cequel::Record) &&
                  !migration_table_names.include?(_cls.table_name.to_sym)
                _cls.synchronize_schema
                migration_table_names << _cls.table_name.to_sym
                puts "Synchronized schema for #{_cls}"
                classes << _cls
              end
            end
          end
        end
      end
    end
  end
end
