require 'cequel'
require 'octocore/record'

module Octo

  class Plan

    include Cequel::Record
    include Octo::Record

    key :id, :int
    key :active, :boolean

    column :name, :text
  end
end

