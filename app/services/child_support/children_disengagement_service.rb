class ChildSupport::ChildrenDisengagementService

  DISENGAGEMENT_STATUSES = ['KO', 'Ne pas appeler', 'Numéro erroné'].freeze
  MESSAGE = "Bonjour,\n{PRENOM_ACCOMPAGNANTE} a essayé de vous appeler plusieurs fois mais n'a pas réussi à discuter avec vous. Avec 1001mots, quand on n'arrive pas à échanger, l'accompagnement se termine pour que d'autres familles en profitent. Les livres et SMS vont donc s'arrêter bientôt.\nMerci d'avoir participé à ce programme. On vous souhaite de beaux moments avec {PRENOM_ENFANT} !\nEt si vous avez encore 1 minute, dites-nous ici ce que vous avez pensé de 1001mots : https://form.typeform.com/to/fysdS3Sd#st=xxxxx\nL'équipe 1001mots".freeze

  attr_reader :errors, :parent_ids

  def initialize(group_id, call_index)
    @group_id = group_id
    @call_index = call_index
    @errors = []
    @message = MESSAGE.dup
    @parents_with_multiple_children = []
    @parents_with_single_child = []
    @parent_ids = []
  end

  def call
    find_child_supports
    return self if @errors.any? || group_without_calls?

    @child_supports.each do |child_support|
      @child_support = child_support
      parent = contactable_parent
      next unless parent

      disengage_active_children_in_group
      child_support.tag_list += ['desengage-2appelsKO']
      child_support.save!
      add_parent_to_recipients(parent)
    end

    send_disengagement_messages
    self
  end

  private

  def find_child_supports
    @group = Group.find_by(id: @group_id)
    @errors << "No group with ID #{@group_id}" and return unless @group

    @child_supports =
      if @group&.type_of_support == 'without_calls'
        []
      else
        case @call_index
        when 1
          ChildSupport.group_id_in(@group_id).with_a_child_in_active_group
                      .where(call1_avoid_disengagement_date: nil)
                      .where('call1_status IN (?, ?, ?)', 'KO', 'Ne pas appeler', 'Numéro erroné')
                      .select { |child_support| child_support.call0_status.in? DISENGAGEMENT_STATUSES }
        when 2
          ChildSupport.group_id_in(@group_id).with_a_child_in_active_group
                      .where(call2_avoid_disengagement_date: nil)
                      .where('call2_status IN (?, ?, ?)', 'KO', 'Ne pas appeler', 'Numéro erroné')
                      .select { |child_support| child_support.call1_status.in?(DISENGAGEMENT_STATUSES) || child_support.call0_status.in?(DISENGAGEMENT_STATUSES) }
        when 3
          ChildSupport.group_id_in(@group_id).with_a_child_in_active_group
                      .where(call3_avoid_disengagement_date: nil)
                      .where('call3_status IN (?, ?, ?)', 'KO', 'Ne pas appeler', 'Numéro erroné')
                      .select { |child_support| child_support.call2_status.in?(DISENGAGEMENT_STATUSES) || child_support.call1_status.in?(DISENGAGEMENT_STATUSES) || child_support.call0_status.in?(DISENGAGEMENT_STATUSES) }
        else
          []
        end
      end
  end

  def group_without_calls?
    @group&.type_of_support == 'without_calls'
  end

  def contactable_parent
    if @child_support.parent1.should_be_contacted?
      @child_support.parent1
    elsif @child_support.parent2&.should_be_contacted?
      @child_support.parent2
    end
  end

  def disengage_active_children_in_group
    @child_support.children
      .where.not(group_status: %w[stopped disengaged not_supported])
      .update(group_status: 'disengaged', group_end: Time.zone.today)
  end

  def add_parent_to_recipients(parent)
    parent_identifier = "parent.#{parent.id}"

    if has_multiple_active_children_in_group?
      @parents_with_multiple_children << parent_identifier
    else
      @parents_with_single_child << parent_identifier
    end

    @parent_ids << parent_identifier
  end

  def has_multiple_active_children_in_group?
    @child_support.children.count do |child|
      child.group_id == @group.id && !child.group_status.in?(%w[disengaged stopped not_supported])
    end > 1
  end

  def send_disengagement_messages
    send_message_to_parents(
      @parents_with_multiple_children,
      @message.gsub('{PRENOM_ENFANT}', 'vos enfants')
    )

    send_message_to_parents(
      @parents_with_single_child,
      @message
    )
  end

  def send_message_to_parents(parent_ids, message)
    return if parent_ids.empty?

    service = ProgramMessageService.new(
      Time.zone.today,
      '13:00',
      parent_ids,
      message,
      nil,
      nil,
      false,
      nil,
      nil,
      ['disengaged']
    ).call

    @errors << "Erreur lors de la programmation du message de désengagement : #{service.errors.join(' - ')}" if service.errors.any?
  end
end
