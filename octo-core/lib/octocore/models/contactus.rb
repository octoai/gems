require 'cequel'

module Octo
  class ContactUs
    include Cequel::Record

    key :email, :text
    column :typeofrequest, :text

    column :firstName, :text
    column :lastName, :text
    column :message, :text

    column :created_at, :timestamp

  end
end