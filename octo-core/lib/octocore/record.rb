module Octo
  module Record

    def unique_id
      candidates = self.key_attributes
      if candidates.length == 1
        # This is most likely going to be the enterpriseid of some sort
        candidates.first[1].to_s
      elsif candidates.length == 2
        if candidates.has_key?(:enterprise_id)
          candidates.delete(:enterprise_id)
          candidates.first[1].to_s
        end
      else
        raise NotImplementedError, 'See Octo::Record#unique_id'
      end
    end

  end
end
