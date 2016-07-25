# octo-core

This is the Octomatic Enterprise Core gem. It provides most of the ORM stuff. Class and modules for different tables.


**Rake Tasks**

```bash
rake cequel:keyspace:create  # Initialize Cassandra keyspace
rake cequel:keyspace:drop    # Drop Cassandra keyspace
rake octo:init               # Create keyspace and tables for all defined models
rake octo:migrate            # Synchronize all models defined in `lib/octocore/models' with Cassandra database schema
rake octo:reset              # Drop keyspace if exists, then create and migrate
rake spec                    # Run RSpec code examples
```

# Building

```bash
./bin/clean_setup.sh
```

# Specs

```
lang=bash
rake spec
```

# Verifying connectivity

You can use the following set of commands in `irb` to verify all things working with this gem. Execute it from irb in PROJ_DIR.

```ruby
require 'octocore';config_dir = 'lib/octocore/config/';Octo.connect_with(config_dir);nil
```

# Creating fake stream

It ships with a utility called `fakestream`. It will automatically stream random data. To use just open your console and type

```
fakestream
```

Optionally provide a config file for octo to connect as 

```
fakestream /path/to/octo_config.yml
```
