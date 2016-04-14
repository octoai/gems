module Octo
  module NewsFeed

    module Weaver

      # Weaves up all the various things to be shown
      #   in the newsfeed
      # @param [Hash{Symbol => Array}] args The products hash
      #   to be used for weaving.
      #   This hash should contain a key which symbolises/groups types
      #   of products - trending, recommended, promoted etc.
      # @param [Hash] opts The options used for weaving
      # @return [Array] Weaved array of items
      def weave(items, opts={})
        order = opts.fetch(:order, weaving_order)

        items_count = items.values.flatten.length
        order_length = order[:tag_items_count].length

        tag_length = order[:tag_order].length

        loop_count = items_count/order_length + items_count%order_length

        _feed = []

        loop_count.times do |i|
          init_index = i*tag_length
          if init_index >= order_length
            init_index = order_length - tag_length
          end
          end_index  = init_index + tag_length
          count_of_tags = order[:tag_items_count].slice(init_index...end_index)
          order[:tag_order].each_with_index do |tag, index|
            _feed.concat(items[tag].take(count_of_tags[index]))
          end
        end
        _feed
      end


      # Returns a hash which contains key the data that decides how the items
      #   would be weaved.
      #
      #   It is a hash containing a key :tag_order that decides the priority
      #   of item groups (like trending, recommended, promoted). This info
      #   is used in understanding the data in other key.
      #
      #   The other key :tag_items_count contains an array of numbers. These
      #   numbers signify the count of each item group that would be used
      #   to generate the news feed.
      #
      #   The last pattern represented by :tag_items_count would keep on
      #     repeating itself if :tag_items_count's length is smaller than
      #     the length of items
      #
      #   Example:
      #
      #     Suppose the items that would constitute the feed are
      #   { trending: Array(10..20),
      #     recommended: Array(30..40),
      #     promoted: Array(50..60)
      #   }
      #
      #   and the corresponding weaving order is as follows
      #     { tag_order: [:trending, :promoted, :recommended],
      #       tag_items_count: [2,3,1, 1,2,1, 3,2,1, 1,0,2, 2,4,0, 1,2,1]
      #     }
      #
      #   Then the generated feed would like like
      #
      #     [10, 11, 30, 31, 32, 50, 10, 30, 31, 50, 10, 11, 12, 30, 31, 50,
      #     10, 50, 51, 10, 11, 30, 31, 32, 33, 10, 30, 31, 50, 10, 30, 31,
      #     50, 10, 30, 31, 50, 10, 30, 31, 50, 10, 30, 31, 50, 10, 30, 31,...
      #
      # @return [Hash] data structure which weaves
      def weaving_order
        {
         tag_order: [:trending, :recommended, :similar],
         tag_items_count: [2,3,1, 1,2,1, 3,2,1, 1,0,2, 2,4,0, 1,2,1]
        }
      end
    end
  end
end