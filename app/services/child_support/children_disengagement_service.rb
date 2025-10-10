class ChildSupport::ChildrenDisengagementService

  MESSAGE = "Bonjour,/n{PRENOM_ACCOMPAGNANTE} n'a pas réussi à discuter avec vous encore une fois. Cet appel fait partie de votre accompagnement 1001mots. Comme on vous l’a dit il y a quelques semaines, l’accompagnement va donc s’arrêter et bientôt vous n’allez plus recevoir de livres ni de SMS (dès la fin de ce thème)./nJe vous souhaite de beaux moments avec {PRENOM_ENFANT}./nEt si vous avez encore 1 minute, dites-nous ici ce que vous avez pensé de 1001mots : https://form.typeform.com/to/fysdS3Sd#st=xxxxx /nL'équipe 1001mots".freeze

  attr_reader :errors, :parent_ids

  def initialize(group_id)
    @group = Group.find(group_id)
    @message = MESSAGE.dup
    @message_planned_date = Time.zone.today
    @message_planned_hour = '13:00'
    @parent_ids = []
    @errors = []
  end

  def call
    return self if @group.type_of_support == 'without_calls'

    ChildSupport.includes(:children).where(children: { id: @group.children.map(&:id) }).tagged_with('desengage-2appelsKO').uniq.each do |child_support|
      @child_support = child_support
      @child_support.children.each { |child| child.update(group_status: 'disengaged', group_end: Time.zone.today) }
      fill_recipients
    end
    send_disengagement_message
    self
  end

  def fill_recipients
    @parent = @child_support.parent1.should_be_contacted? ? @child_support.parent1 : @child_support.parent2
    return unless @parent

    @parent_ids << "parent.#{@parent.id}"
  end

  def send_disengagement_message
    return if @parent_ids.empty?

    disengagement_message_service = ProgramMessageService.new(
      @message_planned_date,
      @message_planned_hour,
      @parent_ids,
      @message,
      nil, nil, false, nil, nil, ['disengaged']
    ).call
    @errors << "Erreur lors de la programmation du message de désengagement : #{disengagement_message_service.errors.join(' -')}" if disengagement_message_service.errors.any?
  end
end
