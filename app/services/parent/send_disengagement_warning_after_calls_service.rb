class Parent::SendDisengagementWarningAfterCallsService

  MESSAGE = [
    <<~MSG1,
      Bonjour,
      {PRENOM_ACCOMPAGNANTE}, de l'association 1001mots, a essayé de vous appeler plusieurs fois. C’est dommage que vous n'ayez pas pu discuter avec elle, parce que c’est super important pour adapter nos astuces à votre famille. Dans 2 semaines, vous allez recevoir le 1er livre pour {PRENOM_ENFANT}. {PRENOM_ACCOMPAGNANTE} vous appellera ensuite pour en parler avec vous.
      Si elle n'arrive pas à vous parler au téléphone, l'accompagnement s'arrêtera automatiquement et vous n'allez plus recevoir de livres ni de SMS :( Pensez à enregistrer son numéro {NUMERO_AIRCALL_ACCOMPAGNANTE}
      A bientôt !
      L’équipe 1001mots
    MSG1
    <<~MSG2,
      Bonjour,
      {PRENOM_ACCOMPAGNANTE}, de l'association 1001mots, a essayé de vous appeler plusieurs fois, mais vous n'étiez pas disponible. C'est dommage, parce que c'est super important pour adapter nos astuces à votre famille. Elle vous rappellera dans quelques semaines.
      Si elle n'arrive pas à vous parler au téléphone, l'accompagnement s'arrêtera automatiquement et vous n'allez plus recevoir de livres ni de SMS :(
      A bientôt !
      L'équipe 1001mots"
    MSG2
    <<~MSG3
      Bonjour,
      {PRENOM_ACCOMPAGNANTE}, de l'association 1001mots, a essayé de vous appeler plusieurs fois, mais vous n'étiez pas disponible. C'est dommage, parce que c'est super important pour adapter nos astuces à votre famille. Elle vous rappellera dans 3 mois.
      Si elle n'arrive pas à vous parler au téléphone, l'accompagnement s'arrêtera automatiquement et vous n'allez plus recevoir de livres ni de SMS :(
      A bientôt !
      L’équipe 1001mots
    MSG3
  ].freeze
  ENGAGEMENT_STATUSES = [ChildSupport.human_attribute_name('call_status.1_ok'), ChildSupport.human_attribute_name('call_status.5_unfinished')].freeze

  attr_reader :errors

  def initialize(group_id, call_index)
    @call_index = call_index.to_i
    @group = Group.find(group_id)
    @errors = []
    @date = Time.zone.today
    @parent_ids = []
  end

  def call
    @child_supports = child_supports
    @parent_ids = @child_supports.map { |child_support| "parent.#{child_support.parent1.id}" }.uniq
    service = ProgramMessageService.new(
      @date.strftime('%d-%m-%Y'),
      '19:00',
      @parent_ids,
      MESSAGE[@call_index]
    ).call
    @errors << "Parent::SendDisengagementWarningAfterCallsService (group: #{@group.name}) : #{service.errors.uniq}" if service.errors.any?
    self
  end

  private

  def child_supports
    case @call_index
    when 0
      @group.child_supports
            .with_a_child_in_active_group
            .where.not('call0_status IN (?, ?)', ChildSupport.human_attribute_name('call_status.1_ok'), ChildSupport.human_attribute_name('call_status.5_unfinished'))
    when 1
      @group.child_supports
            .with_a_child_in_active_group
            .where.not('call1_status IN (?, ?)', ChildSupport.human_attribute_name('call_status.1_ok'), ChildSupport.human_attribute_name('call_status.5_unfinished'))
            .select { |child_support| child_support.call0_status.in? ENGAGEMENT_STATUSES }
    when 2
      @group.child_supports
            .with_a_child_in_active_group
            .where.not('call2_status IN (?, ?)', ChildSupport.human_attribute_name('call_status.1_ok'), ChildSupport.human_attribute_name('call_status.5_unfinished'))
            .select { |child_support| child_support.call0_status.in?(ENGAGEMENT_STATUSES) && child_support.call1_status.in?(ENGAGEMENT_STATUSES) }
    else
      []
    end
  end
end
