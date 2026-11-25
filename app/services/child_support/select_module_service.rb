class ChildSupport::SelectModuleService

  BUNDLE = ['Invitation à choisir le prochain thème', 'invitation_choix_theme'].freeze

  attr_reader :errors, :children_support_module_ids

  def initialize(child, planned_date, planned_hour, module_index)
    @child = child
    @planned_date = planned_date
    @planned_hour = planned_hour
    @module_index = module_index
    @children_support_module_ids = []
    @errors = []
  end

  def call
    if !@child.should_contact_parent1 && !@child.should_contact_parent2
      @errors << 'Aucun des parents ne veut être contacté'

      return self
    end

    send_select_module_message(@child.parent1, @child.child_support.parent1_available_support_module_list) if @child.should_contact_parent1
    send_select_module_message(@child.parent2, @child.child_support.parent2_available_support_module_list) if @child.parent2 && @child.should_contact_parent2
    self
  end

  private

  def send_select_module_message(parent, available_support_module_list)
    return if available_support_module_list.blank?
    return if available_support_module_list.reject(&:blank?).empty?

    @children_support_module = ChildrenSupportModule.find_by(child_id: @child.id, parent_id: parent.id, is_programmed: false)
    @children_support_module ||= ChildrenSupportModule.create!(child_id: @child.id, parent_id: parent.id, available_support_module_list: available_support_module_list, module_index: @module_index)

    if @children_support_module.available_support_module_list.reject(&:blank?).size == 1
      chose_support_module
    else
      @children_support_module_ids << @children_support_module.id
      send_message_to_parent(parent)
    end
  end

  def send_message_to_parent(parent)
    name, key = BUNDLE
    bundle = Media::TextMessagesBundle.find_automatic(name: name, key: key)
    return @errors << Media::TextMessagesBundle.missing_message(name: name, key: key) unless bundle

    sms_service = ProgramAutomaticMessageService.new(
      @planned_date, @planned_hour, ["parent.#{parent.id}"],
      bundle.body1, bundle.rcs_media_id_to_send(1), bundle.redirection_target_id(1),
      automatic_message_key: key, recipient_variables: { parent.id => message_variables(parent) }
    ).call

    @errors += sms_service.errors if sms_service.errors.any?
  end

  def message_variables(parent)
    {
      # module_index starts with 1 : module_index == 3 is "Module 2" (after "Module 0" and "Module 1")
      'DELAI_CHOIX_THEME' => @module_index.eql?(3) && @child.group.with_module_zero? ? 'deux jours' : 'quelques jours',
      'LIEN_CHOIX_THEME' => Rails.application.routes.url_helpers.children_support_module_link_url(@children_support_module.id, sc: parent.security_code),
      'PRENOM_ENFANT' => @child.first_name
    }
  end

  def chose_support_module
    @children_support_module.update(support_module_id: @children_support_module.available_support_module_list.reject(&:blank?).first)
    @errors += @children_support_module.errors.full_messages if @children_support_module.errors.any?
  end
end
