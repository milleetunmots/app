class ChildSupport::ChildrenDisengagementService

  MESSAGE = "Bonjour,\n{PRENOM_ACCOMPAGNANTE} a essayé de vous appeler plusieurs fois mais n'a pas réussi à discuter avec vous. Avec 1001mots, quand on n'arrive pas à échanger, l'accompagnement se termine pour que d'autres familles en profitent. Les livres et SMS vont donc s'arrêter bientôt.\nMerci d’avoir participé à ce programme. On vous souhaite de beaux moments avec {PRENOM_ENFANT} !\nEt si vous avez encore 1 minute, dites-nous ici ce que vous avez pensé de 1001mots : https://form.typeform.com/to/fysdS3Sd#st=xxxxx\nL’équipe 1001mots".freeze

  attr_reader :errors, :parent_ids

  def initialize(group_id)
    @group = Group.find(group_id)
    @message = MESSAGE.dup
    @message_planned_date = Time.zone.today
    @message_planned_hour = '13:00'
    @parent_with_multiple_children_ids = []
    @parent_without_multiple_children_ids = []
    @errors = []
  end

  def call
    return self if @group.type_of_support == 'without_calls'

    ChildSupport.includes(:children).where(children: { id: @group.children.map(&:id) }).tagged_with('desengage-2appelsKO').uniq.each do |child_support|
      @child_support = child_support
      fill_recipients
      @child_support.children.where.not(group_status: %w[stopped disengaged not_supported]).each { |child| child.update(group_status: 'disengaged', group_end: Time.zone.today) }
    end
    send_disengagement_message(@parent_with_multiple_children_ids, @message.gsub('{PRENOM_ENFANT}', 'vos enfants'))
    send_disengagement_message(@parent_without_multiple_children_ids, @message)
    @parent_ids = @parent_without_multiple_children_ids + @parent_with_multiple_children_ids
    self
  end

  def fill_recipients
    @parent = @child_support.parent1.should_be_contacted? ? @child_support.parent1 : @child_support.parent2
    return unless @parent

    if @child_support.children.count { |child| !child.group_status.in? ['disengaged', 'stopped'] } > 1
      @parent_with_multiple_children_ids << "parent.#{@parent.id}"
    else
      @parent_without_multiple_children_ids << "parent.#{@parent.id}"
    end
  end

  def send_disengagement_message(parent_ids, message)
    return if parent_ids.empty?

    disengagement_message_service = ProgramMessageService.new(
      @message_planned_date,
      @message_planned_hour,
      parent_ids,
      message,
      nil, nil, false, nil, nil, ['disengaged']
    ).call
    @errors << "Erreur lors de la programmation du message de désengagement : #{disengagement_message_service.errors.join(' -')}" if disengagement_message_service.errors.any?
  end
end
