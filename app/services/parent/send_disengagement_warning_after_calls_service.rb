class Parent::SendDisengagementWarningAfterCallsService

  MESSAGE = [
    "Bonjour,\n{PRENOM_ACCOMPAGNANTE}, de l'association 1001mots, a essayé de vous appeler plusieurs fois. C’est dommage que vous n'ayez pas pu discuter avec elle, parce que c’est super important pour adapter nos astuces à votre famille. Dans 2 semaines, vous allez recevoir le 1er livre pour {PRENOM_ENFANT}. {PRENOM_ACCOMPAGNANTE} vous appellera ensuite pour en parler avec vous.\nSi elle n'arrive pas à vous parler au téléphone, l'accompagnement s'arrêtera automatiquement et vous n'allez plus recevoir de livres ni de SMS :( Pensez à enregistrer son numéro {NUMERO_AIRCALL_ACCOMPAGNANTE}\nA bientôt !\nL’équipe 1001mots",
    "Bonjour,\n{PRENOM_ACCOMPAGNANTE}, de l'association 1001mots, a essayé de vous appeler plusieurs fois, mais vous n'étiez pas disponible. C'est dommage, parce que c'est super important pour adapter nos astuces à votre famille. Elle vous rappellera dans quelques semaines.\nSi elle n'arrive pas à vous parler au téléphone, l'accompagnement s'arrêtera automatiquement et vous n'allez plus recevoir de livres ni de SMS :(\nA bientôt !\nL'équipe 1001mots",
    "Bonjour,\n{PRENOM_ACCOMPAGNANTE}, de l'association 1001mots, a essayé de vous appeler plusieurs fois, mais vous n'étiez pas disponible. C'est dommage, parce que c'est super important pour adapter nos astuces à votre famille. Elle vous rappellera dans 3 mois.\nSi elle n'arrive pas à vous parler au téléphone, l'accompagnement s'arrêtera automatiquement et vous n'allez plus recevoir de livres ni de SMS :(\nA bientôt !\nL’équipe 1001mots"
  ].freeze


  attr_reader :errors

  def initialize(group_id, call_index)
    @call_index = call_index.to_i
    @group = Group.find(group_id)
    @errors = []
    @date = Time.zone.today
    @child_supports = @group.child_supports.where.not("call#{call_index}status = ? OR call#{call_index}_status = ?", ChildSupport.human_attribute_name('1.ok'), ChildSupport.human_attribute_name('5.unfinished'))
    @parent_ids = @child_supports.map { |child_support| "parent.#{child_support.parent1.id}" }.uniq
  end

  def call
    service = ProgramMessageService.new(
      @date.strftime('%d-%m-%Y'),
      '19:00',
      @parent_ids,
      MESSAGE[@call_index]
    ).call
    @errors << "Parent::SendDisengagementWarningAfterCallsService (group: #{group.name}) : #{service.errors.uniq}" if service.errors
    self
  end
end
