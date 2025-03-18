class ProgramMessageService

  TYPEFORM_URL_REGEX = %r{https://form.typeform.com/[^\s]*#child_support_id=[^\s]+}.freeze
  VIDEOASK_URL_REGEX = %r{https://www\.videoask\.com/[^\s]*#child_support_id=[^\s]+}.freeze

  attr_reader :errors

  def initialize(planned_date, planned_hour, recipients, message, file = nil, redirection_target_id = nil, quit_message = false, workshop_id = nil, supporter = nil, group_status = ['active'], provider = 'spothit', aircall_number_id = nil)
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
    @supporter_id = supporter.nil? ? nil : supporter.to_i
    @group_status = group_status
    @provider = provider
    @aircall_number_id = aircall_number_id
    @errors = []
  end

  def call
    check_all_fields_are_present
    return self if @errors.any?

    find_form_url(TYPEFORM_URL_REGEX)
    find_form_url(VIDEOASK_URL_REGEX)
    get_all_variables if @message.match(/\{(.*?)\}/)
    return self if @errors.any?

    sort_recipients
    find_parent_ids_from_tags
    find_parent_ids_from_groups
    find_parent_ids_from_children
    filter_by_supporter
    filter_by_group_status
    verify_parent_and_children_validity

    return self if @errors.any?

    @errors << 'Aucun parent à contacter.' and return self if @parent_ids.empty?

    @message += ' {URL}' if @redirection_target && !@variables.include?('URL')
    format_data_for_provider
    return self if @errors.any?

    # TO DO: handle programmable aircall messages (messages are sent right away atm)
    service =
      case @provider
      when 'aircall'
        # only one recipient for now when using aircall
        parent = Parent.where(id: @parent_ids).first
        Aircall::SendMessageService.new(number_id: @aircall_number_id, to: parent&.phone_number, body: @message).call
      when 'spothit'
        if @file.nil?
          SpotHit::SendSmsService.new(@recipient_data, @planned_timestamp, @message, workshop_id: @workshop_id, event_params: @event_params).call
        else
          SpotHit::SendMmsService.new(@recipient_data, @planned_timestamp, @message, file: @file, event_params: @event_params).call
        end
      end
    @errors << "Provider inconnu : #{@provider}" and return self if service.blank?

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
      Task::CreateAutomaticTaskService.new(
        title: 'Message non envoyé à des parents',
        description: description_text
      ).call
    end
    self
  end

  protected

  def find_form_url(regex)
    link = @message.scan(regex).first
    return unless link

    hidden_fields = link.split('child_support_id=').second
    hidden_fields_splited = hidden_fields.split('&current_child')
    hidden_fields.gsub!(hidden_fields_splited.second, '_name={PRENOM_ENFANT}') if hidden_fields_splited.second.present?
    hidden_fields.gsub!(hidden_fields_splited.first, '{CHILD_SUPPORT_ID}')

    @message.gsub!(link, link.gsub(link.split('#child_support_id=').second, hidden_fields))
  end

  def get_all_variables
    @variables += @message.scan(/\{(.*?)\}/).transpose[0].uniq

    @errors << 'Veuillez choisir un lien cible.' if @redirection_target.nil? && @variables.include?('URL')
  end

  def increment_suggested_videos_counter(parent)
    return unless @redirection_target.suggested_videos?

    child_support = parent.current_child&.child_support
    return unless child_support

    child_support.suggested_videos_counter << { redirection_target_id: @redirection_target.id, sending_date: Time.zone.now }
    child_support.save(touch: false)
  end

  def format_data_for_provider
    case @provider
    when 'spothit'
      format_data_for_spot_hit
    when 'aircall'
      format_data_for_aircall
    else
      @errors << "Provider inconnu : #{@provider}"
    end
  end

  def format_data_for_aircall
    # TO DO: handle multiple recipents with Aircall
    if @parent_ids.many?
      @errors << "Un seul destinataire possible lors d'un envoi de message Aircall"
    elsif @redirection_target || @variables.any?
      Parent.where(id: @parent_ids).find_each do |parent|
        child_name = parent.current_child&.first_name || 'votre enfant'
        child_support_id = parent.current_child&.child_support&.id
        supporter_name = parent.current_child&.child_support&.supporter&.decorate&.first_name
        supporter_aircall_phone_number = parent.current_child&.child_support&.supporter&.aircall_phone_number
        @message.gsub!('{PRENOM_ENFANT}', child_name)
        @message.gsub!('{CHILD_SUPPORT_ID}', child_support_id)
        @message.gsub!('{PRENOM_ACCOMPAGNANTE}', supporter_name)
        @message.gsub!('{NUMERO_AIRCALL_ACCOMPAGNANTE}', supporter_aircall_phone_number)
        if @redirection_target && parent.current_child.present?
          url = redirection_url_for_a_parent(parent)&.decorate&.visit_url
          increment_suggested_videos_counter(parent)
          @message.gsub!('{URL}', url)
        end
      end
    end
  end

  def format_data_for_spot_hit
    # we need to format phone_numbers as hash inn order to include variables
    if @redirection_target || @variables.any?
      @recipient_data = {}
      Parent.where(id: @parent_ids).find_each do |parent|
        @recipient_data[parent.id.to_s] = {}
        @recipient_data[parent.id.to_s]['PRENOM_ENFANT'] = parent.current_child&.first_name || 'votre enfant'
        @recipient_data[parent.id.to_s]['CHILD_SUPPORT_ID'] = parent.current_child&.child_support&.id
        @recipient_data[parent.id.to_s]['PRENOM_ACCOMPAGNANTE'] = parent.current_child&.child_support&.supporter&.decorate&.first_name
        @recipient_data[parent.id.to_s]['NUMERO_AIRCALL_ACCOMPAGNANTE'] = parent.current_child&.child_support&.supporter&.aircall_phone_number
        if @redirection_target && parent.current_child.present?
          @recipient_data[parent.id.to_s]['URL'] = redirection_url_for_a_parent(parent)&.decorate&.visit_url
          @url = RedirectionUrl.where(redirection_target: @redirection_target, parent: parent).first
          increment_suggested_videos_counter(parent)
        end
      end
    else
      # If no variables, we can just sent an array of parent ids
      @recipient_data = @parent_ids
    end
  end

  def redirection_url_for_a_parent(parent, child_id = nil)
    targeted_child_id = child_id || parent.current_child.id
    redirection_url = parent.redirection_urls.find_by(child_id: targeted_child_id, parent_id: parent.id, redirection_target_id: @redirection_target.id)

    if redirection_url.nil?
      redirection_url = RedirectionUrl.new(
        redirection_target_id: @redirection_target.id,
        parent_id: parent.id,
        child_id: targeted_child_id
      )
      @errors << "Problème(s) avec l'url courte." unless redirection_url.save
    end

    redirection_url
  end

  def check_all_fields_are_present
    @errors << "Les date et heure d'envoi du message sont requises. Veuillez indiquer une date et une heure valide." if @planned_timestamp.blank?
    @errors << 'La liste des destinataires est vide. Ajoutez au moins un destinataire.' if @recipients.empty?
    @errors << 'Un message est requis. Veuillez le compléter.' if @message.empty? && @redirection_target.nil?
    @errors << "L'ID de numéro Aircall est requis" if @aircall_number_id.blank? && @provider == 'aircall'
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

  def filter_by_supporter
    return unless @supporter_id

    parent1_ids = Parent.joins(parent1_children: :child_support).where(id: @parent_ids).where(child_support: { supporter_id: @supporter_id }).ids
    parent2_ids = Parent.joins(parent2_children: :child_support).where(id: @parent_ids).where(child_support: { supporter_id: @supporter_id }).ids
    @parent_ids = (parent1_ids + parent2_ids).uniq
  end

  def filter_by_group_status
    parent1_ids = Parent.joins(:parent1_children).where(id: @parent_ids).where(parent1_children: { group_status: @group_status }).ids
    parent2_ids = Parent.joins(:parent2_children).where(id: @parent_ids).where(parent2_children: { group_status: @group_status }).ids
    @parent_ids = (parent1_ids + parent2_ids).uniq
  end

  def find_parent_ids_from_groups
    Group.includes(:children).where(id: @group_ids).find_each do |group|
      group.children.each do |child|
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
