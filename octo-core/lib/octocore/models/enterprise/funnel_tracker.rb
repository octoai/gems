require 'cequel'

module Octo
  # A model for tracking the user web flow
  # Used to build a markov model on the basis
  #  of the activity. eg p1 --> p2 will be entered
  #  with weight 1, and increased by +1 every time any
  #  user goes from p1 to p2
  class FunnelTracker
    include Cequel::Record

    key :enterprise_id, :uuid

    key :p1, :text
    key :direction, :int
    key :p2, :text
    column :weight, :counter
  end
end