require 'cequel'

# Model for contact us page on the microsite
module Octo
  class ContactUs
    include Cequel::Record

    key :email, :text
    key :created_at, :timestamp

    column :typeofrequest, :text
    column :firstname, :text
    column :lastname, :text
    column :message, :text

    after_create :send_email

    # Send Email after model save
    def send_email
      :subject = 'Octo - Contact Us'
    	opts = {
    		text: self.message,
    		name: self.firstname + ' ' + self.lastname
    	}
    	Octo::Email.send(self.email, :subject, opts)
    end

  end
end