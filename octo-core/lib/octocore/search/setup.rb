module Octo

    # Setup module for ElasticSearch
    module Setup

      # Creates the necessary indices
      class Create

        def self.perform
          sclient = Octo::Search::Client.new
          sconfig = Octo.get_config(:search)

          # Set the cluster disk space thresholds first. That's necessary
          # because the defaults are too less for development machines. So,
          # in order to keep it moving, we set a lower threshold in development.
          # Refer
          # https://www.elastic.co/guide/en/elasticsearch/reference/current/disk-allocator.html
          if sconfig.has_key?(:disk_threshold_low) and sconfig.has_key?(:disk_threshold_high)
            cluster_settings = {
              body: {
                persistent: {
                  'cluster.routing.allocation.disk.threshold_enabled' => true,
                  'cluster.routing.allocation.disk.watermark.low' => sconfig[:disk_threshold_low],
                  'cluster.routing.allocation.disk.watermark.high' => sconfig[:disk_threshold_high],
                  'cluster.info.update.interval' => '60s'
                }
              }
            }
            sclient.cluster.put_settings cluster_settings
          end

          # Check if any indices specified exists. If not exists, create them
          sconfig[:index].keys.each do |index_name|
            args = { index: index_name }
            if sclient.indices.exists?(args)
              Octo.logger.info "Search Index: #{ index_name } exists."
            else
              Octo.logger.warn "Search Index: #{ index_name } DOES NOT EXIST."
              Octo.logger.info "Creating Index: #{ index_name }"
              create_args = {
                index: index_name,
                body: sconfig[:index][index_name]
              }
              sclient.indices.create create_args
            end
          end

          # Also check if there are any indices present that should not be
          # present
          _indices = JSON.parse(sclient.cluster.state)['metadata']['indices'].
            keys.map(&:to_sym)
          extra_indices = _indices - sconfig[:index].keys
          Octo.logger.warn "Found extra indices: #{ extra_indices }"
        end
      end

      # Updates the indices.
      #   The major differene between this and the Create is that while create
      #   just checks for the existance by name, and passes if the name is found
      #   This actually overwrites all the mappings, properties, warmers etc
      #   So, this should be used only when we need to explicitly "UPDATE" the
      #   index.
      class Update

      end


    end


end
