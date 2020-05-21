class ExportQuitMessagesService

  attr_reader :errors, :csv

  def initialize(children:)
    @children = children
    @errors = []
  end

  def call
    if @children.without_parent_to_contact.any?
      @errors << "Certains enfants n'ont aucun parent à contacter"
      return self
    end

    objects = []
    latest_parent1_id = nil
    @children.order(:parent1_id).each do |child|
      next if latest_parent1_id == child.parent1_id
      latest_parent1_id = child.parent1_id

      quit_link = Rails.application.routes.url_helpers.edit_child_url(
        id: child.id,
        security_code: child.security_code
      )
      # ActionMailer::Base.default_url_options

      if child.should_contact_parent1?
        objects << {
          parent: child.parent1,
          child: child,
          quit_link: quit_link
        }
      end

      if child.should_contact_parent2? && child.parent2
        objects << {
          parent: child.parent2,
          child: child,
          quit_link: quit_link
        }
      end
    end

    variables = {
      quit_link: 'Lien court'
    }

    service = GenerateBuzzExpertMessagesService.new(
      objects: objects,
      variables: variables
    ).call

    @errors = service.errors
    @csv = service.csv

    self
  end

end
