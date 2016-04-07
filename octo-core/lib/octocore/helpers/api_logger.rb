require 'logger'

module Octo
  class ApiLogger
    def self.logger
      if @_logger.nil?
        @_logger = Logger.new STDOUT
        @_logger.level = Logger::INFO
        @_logger.datetime_format = '%a %d-%m-%Y %H%M '
      end
      @_logger
    end
  end
end