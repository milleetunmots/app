class ProgramMessageService

  attr_reader :errors

  def initialize(planned_date, planned_hour, recipients, message, file = nil, redirection_target_id = nil, quit_message = false, workshop_id = nil, supporter = nil)
    @planned_timestamp = ActiveSupport::TimeZone['Europe/Paris'].parse("#{planned_date} #{planned_hour}").to_i
    @recipients = recipients || []
    @message = message
    @file = file
    @tag_ids = []
    @parent_ids = []
    @redirection_target = RedirectionTarget.find(redirection_target_id) if redirection_target_id
    @group_ids = []
    @recipient_data = []
    @variables = []
    @child_ids = []
    @quit_message = quit_message
    @workshop_id = workshop_id
    @event_params = {}
    @invalid_parent_ids = []
    @supporter_id = supporter.to_i
    @errors = []
  end

  def call
    check_all_fields_are_present
    return self if @errors.any?

    get_all_variables if @message.match(/\{(.*?)\}/)
    return self if @errors.any?

    sort_recipients
    find_parent_ids_from_tags
    find_parent_ids_from_groups
    find_parent_ids_from_children
    verify_parent_and_children_validity

    return self if @errors.any?

    @errors << 'Aucun parent à contacter.' and return self if @parent_ids.empty?

    format_data_for_spot_hit
    return self if @errors.any?

    @message += ' {URL}' if @redirection_target && !@variables.include?('URL')

    service = if @file.nil?
                SpotHit::SendSmsService.new(@recipient_data, @planned_timestamp, @message, event_params: @event_params).call
              else
                SpotHit::SendMmsService.new(@recipient_data, @planned_timestamp, @message, file: @file, event_params: @event_params).call
              end

    if service.errors.any?
      @errors = service.errors
    elsif @invalid_parent_ids.any?
      invalid_parents = Parent.includes(:parent1_children, :parent2_children).where(id: @invalid_parent_ids)
      description_text = "Le message \"#{@message}\" n'a pas été envoyé aux parents pour les raisons suivantes :"

      invalid_parents.each do |parent|
        if parent.valid?
          parent.children.each do |child|
            unless child.valid?
              @errors << "Message non envoyé à #{parent.decorate.name} parce que son enfant #{child.decorate.name} n'est pas valide"
              description_text << "<br>#{ActionController::Base.helpers.link_to(child.decorate.name, Rails.application.routes.url_helpers.edit_admin_child_url(id: child.id), target: '_blank')} : #{child.errors.messages.to_json}"
            end
          end
        else
          @errors << "Message non envoyé à #{parent.decorate.name} parce qu'il n'est pas valide"
          description_text << "<br>#{ActionController::Base.helpers.link_to(parent.decorate.name, Rails.application.routes.url_helpers.edit_admin_child_url(id: parent.id), target: '_blank')} : #{parent.errors.messages.to_json}"
        end
      end
      AdminUser.all_logistics_team_members.each do |admin_user|
        Task.create(
          assignee_id: admin_user.id,
          title: 'Message non envoyé à des parents',
          description: description_text,
          due_date: Time.zone.today
        )
      end
    end

    self
  end

  protected

  def get_all_variables
    @variables += @message.scan(/\{(.*?)\}/).transpose[0].uniq

    @errors << 'Veuillez choisir un lien cible.' if @redirection_target.nil? && @variables.include?('URL')
  end

  def format_data_for_spot_hit
    # we need to format phone_numbers as hash inn order to include variables
    if @redirection_target || @variables.include?('PRENOM_ENFANT')
      @recipient_data = {}

      Parent.where(id: @parent_ids).find_each do |parent|
        @recipient_data[parent.id.to_s] = {}

        @recipient_data[parent.id.to_s]['PRENOM_ENFANT'] = parent.current_child&.first_name || 'votre enfant'

        if @redirection_target && parent.current_child.present?
          @recipient_data[parent.id.to_s]['URL'] = redirection_url_for_a_parent(parent)&.decorate&.visit_url

          @url = RedirectionUrl.where(redirection_target: @redirection_target, parent: parent).first
        end
      end
    else
      # If no variables, we can just sent an array of parent ids
      @recipient_data = @parent_ids
    end
  end

  def redirection_url_for_a_parent(parent)
    redirection_url = parent.redirection_urls.find_by(child_id: parent.current_child.id, parent_id: parent.id, redirection_target_id: @redirection_target.id)

    if redirection_url.nil?
      redirection_url = RedirectionUrl.new(
        redirection_target_id: @redirection_target.id,
        parent_id: parent.id,
        child_id: parent.current_child.id
      )
      @errors << "Problème(s) avec l'url courte." unless redirection_url.save
    end

    redirection_url
  end

  def check_all_fields_are_present
    @errors << "La date n'est pas complétée." unless @planned_timestamp.present?
    @errors << 'Les destinataires ne sont pas complétés.' if @recipients.empty?
    @errors << "Le message n'est pas complété." if @message.empty?
  end

  def sort_recipients
    @recipients.each do |recipient_id|
      if recipient_id.include? 'parent.'
        @parent_ids << recipient_id[/\d+/].to_i
      elsif recipient_id.include? 'tag.'
        @tag_ids << recipient_id[/\d+/].to_i
      elsif recipient_id.include? 'group.'
        @group_ids << recipient_id[/\d+/].to_i
      elsif recipient_id.include? 'child.'
        @child_ids << recipient_id[/\d+/].to_i
      end
    end
  end

  def find_parent_ids_from_tags
    @tag_ids.each do |tag_id|
      # taggable_id = id of the parent in our case
      @parent_ids += Tagging.by_taggable_type('Parent').by_tag_id(tag_id).pluck(:taggable_id)
    end
  end

  def find_parent_ids_from_groups
    Group.includes(:children).where(id: @group_ids).find_each do |group|
      group.children.each do |child|
        next unless child.group_status == 'active'

        next if @supporter_id.present? && child.child_support.supporter_id != @supporter_id

        @parent_ids << child.parent1_id if child.parent1_id && child.should_contact_parent1
        @parent_ids << child.parent2_id if child.parent2_id && child.should_contact_parent2
      end
    end
  end

  def find_parent_ids_from_children
    Child.where(id: @child_ids).find_each do |child|
      @parent_ids << child.parent1_id if child.parent1_id && child.should_contact_parent1
      @parent_ids << child.parent2_id if child.parent2_id && child.should_contact_parent2
    end
  end

  def verify_parent_and_children_validity
    parents = Parent.includes(:parent1_children, :parent2_children).where(id: @parent_ids)

    parents.each do |parent|
      if parent.valid?
        parent.children.each do |child|
          @invalid_parent_ids << @parent_ids.delete(parent.id) unless child.valid?
        end
      else
        @invalid_parent_ids << @parent_ids.delete(parent.id)
      end
    end
  end
end
