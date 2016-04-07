require 'cassandra'
require 'trending'
require 'productRecommender'

class Newsfeed

  # The max quantity of trending products that need to be fetched and displayed
  #   in the newsfeed
  MAX_TRENDING_PRODUCTS = 10

  # The max qty of products that should be shown in the newsfeed
  MAX_FEED_ITEMS = 30

  # The last N views for a user to look at, in order to generate
  # similar products
  USER_PRODUCT_VIEWS_COUNT = 5

  KEYSPACE = 'octo'

  def initialize
    @cluster = Cassandra.cluster
    @session = @cluster.connect(KEYSPACE)

    @fetcher = ProductRecommender::Fetcher.new
    @trending = Trending::TrendingProducts.new

    cql = "SELECT productid FROM productpage_view WHERE enterpriseid = ? \
    AND userid = ? ORDER BY created_at DESC LIMIT #{ USER_PRODUCT_VIEWS_COUNT }"

    @lastProductsSeen = @session.prepare(cql)
  end

  # Finds out newsfeed for a user
  # @param [String] enterpriseid The ID of enterprise to whom the user belongs
  # @param [Fixnum] userid The ID of user whose feed is to be generated
  def for(enterpriseid, userid)
    enterpriseid = Cassandra::Uuid.new enterpriseid

    _trending = getTrendingProducts(enterpriseid)

    _recommendations = getRecommendedProducts(enterpriseid, userid)
    if _recommendations.empty?
      _recommendations = getSimilarProducts(enterpriseid, userid)
    end

    feed = weave(_recommendations, _trending)
    feed
  end

  private

  # Get recommended products for a user
  # @param [String] enterpriseid The ID of the enterprise
  # @param [Fixnum] userid The ID of user for whom recommended products is to be
  #   generated
  # @return [Array<Fixnum>] An array of products that should be recommended
  #   to the user
  def getRecommendedProducts(enterpriseid, userid)
    _uid = [enterpriseid, userid].join(
      ProductRecommender::Recommender::SEPARATOR)
    @fetcher.predictions_for(enterpriseid, userid)
  end

  # Find similar products as per user's viewing history.
  # @param [String] enterpriseid The ID of enterprise to whom the user belongs
  # @param [Fixnum] userid The ID of user whose viewing history to be
  #   considered
  # @return [Array<Fixnum>] Array of product IDs which are similar
  def getSimilarProducts(enterpriseid, userid)
    # get user's last USER_PRODUCT_VIEWS_COUNT viewing items
    lastViewedItems = []
    args = [Cassandra::Uuid.new(enterpriseid), userid]
    res = @session.execute(@lastProductsSeen, arguments: args)
    if res.length > 0
      res.each do |r|
        lastViewedItems << r['productid']
      end
    end

    _similarProducts = []
    if lastViewedItems.empty?
      puts "Can not find any viewing history"
    else
      lastViewedItems.each do |pid|
        _similarProducts.concat(@fetcher.similarities_for(enterpriseid, pid))
      end
    end

    _similarProducts
  end

  # Get trending product for the enterprise at the given time
  # @param [String] enterpriseid The ID of the enterprise for whom trending
  #   products are to be found
  # @return [Array<Fixnum>] An array of products that are trending at the given
  #   moment
  def getTrendingProducts(enterpriseid)
    _trending = @trending.at(Time.now, enterpriseid)

    # This list needs to be sorted and return only first N elements
    Hash[_trending.sort_by { |k,v| v }].keys[0...MAX_TRENDING_PRODUCTS]
  end

  # Weaves the results from recommendations and trending to form a unified
  #   newsfeed. The way it weaves is 3 recommended products and 2 trending
  #   product. In that order
  # @param [Array<Fixnum>] recommendations The recommended products for the user
  # @param [Array<Fixnum>] trending The trending products for the enterprise
  # @return [Array<Fixnum>] The combined products list to show to user
  def weave(recommendations, trending)
    _feed = []
    while !(recommendations.empty? and trending.empty?)
      _feed.concat(recommendations.shift(3))
      _feed.concat(trending.shift(2))
    end

    # make sure there are no duplicates
    _feed.uniq!

    # fallback cases for feed product count
    if _feed.empty?
      puts "FEED is empty"
      []
    elsif _feed.length < MAX_FEED_ITEMS
      _feed
    elsif _feed.length > MAX_FEED_ITEMS
      _feed[0...MAX_FEED_ITEMS]
    end
  end
end
