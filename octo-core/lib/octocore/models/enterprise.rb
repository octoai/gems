require 'cequel'

module Octo
  class Enterprise
    include Cequel::Record

    # Set ttl of 120 minutes for the caches
    TTL = 120

    key :id, :uuid, auto: true
    column :name, :varchar

    has_many :users, class_name: 'Octo::User'
    has_many :segments, class_name: 'Octo::Segment'
    has_many :templates, class_name: 'Octo::Template'
    has_many :funnels, class_name: 'Octo::Funnel'
    has_many :conversions, class_name: 'Octo::Conversions'

    after_save :_setup

    # Setup the new enterprise
    def _setup
      setup_notification_categories
      setup_intelligent_segments
    end

    # Method to check if it is okay to create fakedata for this
    #   client
    # @return [Boolean]
    def fakedata?
      self.name.start_with?('Octo')
    end

    private

    # Setup the notification categories for the enterprise
    def setup_notification_categories
      templates = Octo.get_config(:push_templates)
      if templates
        templates.each do |t|
          args = {
            enterprise_id: self.id,
            category_type: t[:name],
            template_text: t[:text],
            active: true
          }
          Octo::Template.new(args).save!
        end
        Octo.logger.info("Created templates for Enterprise: #{ self.name }")
      end
    end

    # Setup the intelligent segments for the enterprise
    def setup_intelligent_segments
      segments = Octo.get_config(:intelligent_segments)
      if segments
        segments.each do |seg|
          args = {
            enterprise_id: self.id,
            name: seg[:name],
            type: seg[:type].constantize,
            dimensions: seg[:dimensions].collect(&:constantize),
            operators: seg[:operators].collect(&:constantize),
            values: seg[:values].collect(&:constantize),
            active: true,
            intelligence: true,
          }
          Octo::Segment.new(args).save!
        end
        Octo.logger.info "Created segents for Enterprise: #{ self.name }"
      end
    end

  end

end
