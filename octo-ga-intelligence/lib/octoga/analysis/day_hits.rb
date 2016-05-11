require 'csv'
require 'descriptive_statistics'
require 'ai4r'
require 'benchmark'

class Array
  def rjust!(n, x); insert(0, *Array.new([0, n-length].max, x)) end
  def ljust!(n, x); fill(x, length...n) end
end

module Octo
  module GA
    module Analysis

      class DayHits

        # Performs analysis
        # @param [Array<Hash>] data
        # @return [Hash]
        def self.perform(data, cluster_count = 30, opts={})
          self._data
          clean_data = self.clean data
          trend_data = self.view_trend clean_data
          @data = trend_data
          cluster = self.cluster trend_data, cluster_count ,opts
          self.plot cluster, opts

        end

        def self.clean(data)
          clean_data = {}
          grouped_data = data.group_by { |x| x.page }
          grouped_data.each do |page, counters|
            clean_data[page] = {}
            counters.sort_by { |c| c.date }.reverse.each_with_index do |c,i|
              clean_data[page][i] = c.pageviews
            end
          end
          clean_data
        end

        def self.view_trend(data)
          all_day0_hits = data.values.collect { |x| x[0] }
          day0_baseline = all_day0_hits.mean
          data.inject({}) do |trend, counters|
            page = counters[0]
            cnt = counters[1]
            trend[page] = cnt.values.each_cons(2).map { |a,b| ((b-a)/a).round(3) }
=begin
            day0_slope = (cnt[0] - day0_baseline)/day0_baseline
            #day0_slope = 1

            trend[page].unshift day0_slope
=end
            trend
          end
        end

        # Normalizes the data so that each day represents the %age of total hits
        #   across all days for that article
        def self.normalize(data)
          nd = {}
          data.collect do |page, counters|
            sum = counters.values.inject(0) { |s,x| s + (x or 0) }
            nd[page] = {}
            counters.values.collect { |x| 100.0 * (x or 0)/sum }.each_with_index do |c,i|
              nd[page][i] = c
            end
          end
        end

        def self.som(opts={})
          unless @som
            # set defaults to the source
            nodes = opts.fetch(:nodes, 8)
            layer_nodes = opts.fetch(:layer_nodes, nodes)
            learning_rate = opts.fetch(:learning_rate, 0.7)

            phase_one = opts.fetch(:phase_one, 150)
            phase_two = opts.fetch(:phase_two, 100)
            phase_one_learning_rate = opts.fetch(:phase_one_learning_rate, 0.1)
            phase_two_learning_rate = opts.fetch(:phase_two_learning_rate, 0.0)

            datasize = opts.fetch(:datasize, 10)
            @som = Ai4r::Som::Som.new(datasize, nodes,
                                     Ai4r::Som::TwoPhaseLayer.new(layer_nodes,
                                                                  learning_rate,
                                                                  phase_one,
                                                                  phase_two,
                                                                  phase_one_learning_rate,
                                                                  phase_two_learning_rate))
          end
          @som
        end

        def self.som_clustering(data, opts={})
          datasize = opts.fetch(:datasize, 7)
          data_set = self.data_set_for(data, datasize)

          rev_clustered_data = Hash[data_set.collect {|x| Set.new(x) }.zip(data.keys)]

          som = self.som opts.merge({ datasize: datasize })
          som.initiate_map
          times = Benchmark.measure do
            som.train data_set
          end
          $stdout.puts "SOM Training time: #{ times }"
          clustered_data = Hash.new([])
          data_set.each do |data_item|
            _t = Set.new(data_item)
            page = rev_clustered_data[_t]
            if data.has_key?page
              bmu_node = som.find_bmu(data_item)[0]
              if clustered_data.has_key?(bmu_node.id)
                clustered_data[bmu_node.id] = clustered_data[bmu_node.id] << data_item
              else
                clustered_data[bmu_node.id] = [data_item]
              end
            end
          end
#          clustered_data.delete_if { |k,v| v.count < opts.fetch(:threshold, 5) }
          clustered_data
        end

        def self.data_set_for(data, duration)
          data_set = data.values.collect do |x|
            (x.class == Array) ? x.slice(0, duration) : data.values.slice(0, duration)
          end
          data_set.collect { |x| x.ljust!(duration, 0) }.uniq
        end

        # Does the clustering on normalized data
        def self.cluster(data, cluster_num = 30, opts={})
          clustered_data = {}
          rev_clustered_data = Hash.new([])

          # equalise the dimension for clustering
          max_data_size = opts.fetch(:datasize, 7)

          data_set = self.data_set_for(data, max_data_size)

          clustered_data = Hash[data.keys.zip(data_set)]
          rev_clustered_data = Hash[data_set.collect { |x| Set.new(x) }.zip(data.keys)]

          lbl = Array.new(max_data_size) { |i| 'Day_' + (i+1).to_s }
          ds = Ai4r::Data::DataSet.new(data_items: data_set, data_labels: lbl)

          # Perform Clustering
          klass = opts.fetch(:clusterer, Ai4r::Clusterers::WeightedAverageLinkage)
          clusterer = klass.new.build(ds, cluster_num)

          # Filtering
          clusterer.clusters.delete_if do |x|
            x.data_items.count < opts.fetch(:filter_threshold, 3)
          end

          _t = clusterer

          clusterer.clusters.each_with_index do |cluster, index|
            cluster.data_items.each do |data_item|
              temp = Set.new(data_item)
              page = rev_clustered_data[temp]
              if clustered_data.has_key?page
                clustered_data[page] = [index]
              end
            end
          end
          [_t, clustered_data]
        end

        # Gets the data instance variable
        # @return [Hash]
        def self._data
          @data = {} unless @data
          @data
        end

        # Export the data as a CSV file provided by the filename
        # @param [String] filename
        def self.export(filename, data = self._data)
          CSV.open(filename, 'wb') do |csv|
            data.each do |k,v|
              csv << [k].concat(v.class == Array ? v : v.values)
            end
          end
        end

        def self.plot2(data_cluster, file = '/tmp/cluster2.png', opts = {})
          total_clusters = data_cluster.keys.count
          all_data_count = data_cluster.values.inject(0) do |sum, cluster|
            sum += cluster.count
          end

          title = "#{ opts.fetch(:title, "Clusters: #{ total_clusters }") }. Size: #{ all_data_count }"

          columns = opts.fetch(:columns, 3)
          rows = ((1.0 * total_clusters)/columns).ceil

          size_x = columns * opts.fetch(:chart_size_x, 600)
          size_y = rows * opts.fetch(:chart_size_y, 800)

          xlabel = opts.fetch(:xlabel, 'Days')
          ylabel = opts.fetch(:ylabel, 'Slope')

          lmargin = opts.fetch(:lmargin, 4).to_s
          bmargin = opts.fetch(:bmargin, 4).to_s

          font = opts.fetch(:font, "'4'")

          Gnuplot.open do |gp|
            gp << "set terminal png size #{ size_x }, #{ size_y } nocrop\n
            set output '#{ file }'\n
            set multiplot layout #{ rows }, #{ columns} title '#{ title }'\n"

            data_cluster.each do |cluster_id, cluster_items|
              maxd = cluster_items.inject(0) { |r,e| r = (r < e.length) ? e.length : r }
              x_labels = Array.new(maxd) { |i| i }
              title = "'Cluster: #{ cluster_id}, Set Count: #{ cluster_items.count }'"
              Gnuplot::Plot.new(gp) do |plot|
                plot.set "title", title
                plot.xlabel xlabel
                plot.ylabel ylabel
                plot.lmargin lmargin
                plot.bmargin bmargin
                plot.nokey
                plot.xtics 'nomirror'
                plot.font font

                cluster_items.each do |cluster|
                  plot.data << Gnuplot::DataSet.new([x_labels, cluster]) do |ds|
                    ds.with = 'linespoints'
                  end
                end

              end
            end
          end
        end

        # Plot the graph
        def self.plot(data, file = '/tmp/cluster.png', opts={})
          total_clusters = data.clusters.count
          all_data_count = data.clusters.inject(0) do |sum, cluster|
            sum += cluster.data_items.count
          end

          title = "Slope Analysis #{ total_clusters } clusters. Total Set Size:#{ all_data_count }"

          columns = 3
          rows = ((1.0 * total_clusters)/columns).ceil

          Gnuplot.open do |gp|
            size_x = opts.fetch(:size_x, 1440)
            size_y = opts.fetch(:size_y, 1440)
            gp << "set terminal png size #{ size_x },#{ size_y } nocrop\n
            set output '#{ file }'\n
            set multiplot layout #{ rows },#{ columns } title '#{ title }'\n"

            data.clusters.each_with_index do |cluster, i|
              zz = cluster.data_items.collect { |x| x.keep_if { |j| j!= 0 } }
              maxd = zz.inject(0) { |r,e| r = (r < e.length) ? e.length : r }
              zz.each { |x| x.ljust!(maxd, 0) }
              title = "Cluster: #{ i }, Cardinality: #{ zz.count }"

              Gnuplot::Plot.new(gp) do |plot|
                plot.set "title", title
                plot.xlabel 'Days from beginning of content launch'
                plot.ylabel 'Growth from last day'
                plot.lmargin '4'
                plot.nokey
                plot.bmargin '3'
                plot.xtics 'nomirror'
                plot.font "'4'"

                a = Array.new(maxd) { |x| x }

                zz.each do |x|
                  plot.data << Gnuplot::DataSet.new([a, x]) do |ds|
                    ds.with = 'linespoints'
                  end
                end
              end

            end
          end

        end

      end
    end
  end
end

