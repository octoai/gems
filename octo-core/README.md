# octo-core

This is the Octomatic Enterprise Core gem. It provides most of the ORM stuff. Class and modules for different tables.


**Rake Tasks**

```bash
rake cequel:keyspace:create  # Initialize Cassandra keyspace
rake cequel:keyspace:drop    # Drop Cassandra keyspace
rake octo:init               # Create keyspace and tables for all defined models
rake octo:migrate            # Synchronize all models defined in `lib/octocore/models' with Cassandra database schema
rake octo:reset              # Drop keyspace if exists, then create and migrate
```

# Building

```bash
./bin/clean_setup.sh
```

# Verifying connectivity

You can use the following set of commands in `irb` to verify all things working with this gem. Execute it from irb in PROJ_DIR.

```ruby
%w(octocore yaml).each { |x| require x }
config_file = 'lib/octocore/config/config.yml'
config = YAML.load_file(config_file).deep_symbolize_keys
Octo.connect(config)
```
