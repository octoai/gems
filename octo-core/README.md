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
