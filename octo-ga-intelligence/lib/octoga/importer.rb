require 'smarter_csv'
require 'ostruct'

module Octo

  module Importer

    # Date converter from GA style to Ruby Time
    class DateConverter
      def self.convert(value)
        Date.strptime( value.to_s, '%Y%m%d') rescue nil
      end
    end

    # Number converter from GA style to Ruby Fixnum
    class NumberConverter
      def self.convert(value)
        value.to_s.gsub(/[^0-9\.]/,'').to_f
      end
    end

    # Convert string Lap time (like time spent) into
    #   day fraction for comparisons
    class TimeToDayFraction
      def self.convert(value)
        hh, mm, ss = value.split(':').map(&:to_i)
        Rational(hh * 3600 + mm * 60 + ss, 86400)
      end
    end

    # Not just a wrapper around SMarterCSV
    class CSVImporter

      # Adds a wrapper that knows converters for different
      #   GA types. Refer SmarterCSV.process
      def self.process(filename, options={}, &block)
        opts = options.merge({
          comment_regexp: /^#/,
          strip_chars_from_headers: /(%|\.|\s)/,
          value_converters: {
            date: Octo::Importer::DateConverter,
            pageviews: Octo::Importer::NumberConverter,
            unique_pageviews: Octo::Importer::NumberConverter,
            avg_time_on_page: Octo::Importer::TimeToDayFraction,
            entrances: Octo::Importer::NumberConverter,
            bounce_rate: Octo::Importer::NumberConverter,
            exit: Octo::Importer::NumberConverter,
            page_value: Octo::Importer::NumberConverter,
            uniquepageviews: Octo::Importer::NumberConverter
          }
        })
        SmarterCSV.process(filename, opts, &block).collect do |x|
          OpenStruct.new x
        end
      end
    end

  end

end

