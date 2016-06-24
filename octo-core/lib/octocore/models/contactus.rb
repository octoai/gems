require 'cequel'
# Model for contavt us page on the microsite
module Octo
  class ContactUs
    include Cequel::Record

    key :email, :text
    key :created_at, :timestamp

    column :typeofrequest, :text
    column :firstname, :text
    column :lastname, :text
    column :message, :text


  end
end