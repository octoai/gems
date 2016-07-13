require 'set'

module Octo

  module Utils

    class << self

      # Serialize one record before adding it to the cache. Creates a ruby byte
      #   stream
      # @param [Object] record Any object to be serialized
      def serialize(record)
        Marshal::dump(record).to_s
      end

      # Deserialize a data.
      # @param [String] data A string containing Marshal dump of the object
      def deserialize(data)
        Marshal::load(data)
      end
    end
  end
end

class ::Time

  # Find floor time
  # @param [Fixnum] height The minutes of height for floor. Defaults to 1
  def floor(height = 1)
    if height < 1
      height = 1
    end
    sec = height.to_i * 60
    Time.at((self.to_i / sec).round * sec)
  end

  # Find ceil time
  # @param [Fixnum] height The minutes of height for ceil. Defaults to 1
  def ceil(height = 1)
    if height < 1
      height = 1
    end
    sec = height.to_i * 60
    Time.at((1 + (self.to_i / sec)).round * sec)
  end

  # Finds the steps between two time.
  # @param [Time] to The end time
  # @param [Time] step The step time. Defaults to 15.minute
  # @return [Array<Time>] An array containint times
  def to(to, step = 15.minutes)
    [self].tap { |array| array << array.last + step while array.last < to }
  end

end

class ::String

  # Create a custom method to convert strings to Slugs
  def to_slug
    #strip the string
    ret = self.strip

    #blow away apostrophes
    ret.gsub!(/['`]/,'')

    # @ --> at, and & --> and
    ret.gsub!(/\s*@\s*/, ' at ')
    ret.gsub!(/\s*&\s*/, ' and ')

    #replace all non alphanumeric, underscore or periods with underscore
    ret.gsub!(/\s*[^A-Za-z0-9\.\-]\s*/, '_')

    #convert double underscores to single
    ret.gsub!(/_+/,'_')

    #strip off leading/trailing underscore
    ret.gsub!(/\A[_\.]+|[_\.]+\z/,'')

    ret
  end

end

class ::Hash
  def deep_merge(second)
    merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : Array === v1 && Array === v2 ? v1 | v2 : [:undefined, nil, :nil].include?(v2) ? v1 : v2 }
    self.merge(second.to_h, &merger)
  end
end
