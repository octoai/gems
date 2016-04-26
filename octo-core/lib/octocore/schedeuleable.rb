require 'octocore/counter'

module Octo
  module Scheduleable

    def perform(*args)
      type = args[0].to_sym

      if Octo::Counter.constants.include?type
        if type == :TYPE_MINUTE and self.respond_to?(:aggregate!)
          aggregate!
        else
          method_name = type_counters_method_names type
          send(method_name.to_sym, Time.now.floor)
        end
      end
    end

  end
end