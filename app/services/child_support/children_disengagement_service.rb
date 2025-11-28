class ChildSupport::ChildrenDisengagementService
  MESSAGE = "Bonjour,\n{PRENOM_ACCOMPAGNANTE} a essayé de vous appeler plusieurs fois mais n'a pas réussi à discuter avec vous. Avec 1001mots, quand on n'arrive pas à échanger, l'accompagnement se termine pour que d'autres familles en profitent. Les livres et SMS vont donc s'arrêter bientôt.\nMerci d'avoir participé à ce programme. On vous souhaite de beaux moments avec {PRENOM_ENFANT} !\nEt si vous avez encore 1 minute, dites-nous ici ce que vous avez pensé de 1001mots : https://form.typeform.com/to/fysdS3Sd#st=xxxxx\nL'équipe 1001mots".freeze

  attr_reader :errors, :parent_ids

  def initialize(group_id)
    @group = Group.find(group_id)
    @errors = []
    @message = MESSAGE.dup
    @parents_with_multiple_children = []
    @parents_with_single_child = []
    @parent_ids = []
  end

  def call
    return self if group_without_calls?

    ChildSupport
      .includes(:children)
      .where(children: { id: @group.children.map(&:id) })
      .tagged_with('desengage-2appelsKO')
      .uniq
      .each do |child_support|
        @child_support = child_support
        parent = contactable_parent
        next unless parent

        disengage_active_children_in_group
        add_parent_to_recipients(parent)
      end

    send_disengagement_messages
    self
  end

  private

  def group_without_calls?
    @group.type_of_support == 'without_calls'
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

    if service.errors.any?
      @errors << "Erreur lors de la programmation du message de désengagement : #{service.errors.join(' - ')}"
    end
  end
end
