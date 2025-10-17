class Parent::SendDisengagementWarningBeforeCallsService

  MESSAGE = [
    "Bonjour,\nC'est le début de votre accompagnement avec l'association 1001mots, qui va vous envoyer des SMS et des livres pour {PRENOM_ENFANT}. {PRENOM_ACCOMPAGNANTE} va bientôt vous appeler pour vous expliquer comment ça se passe, faire connaissance et discuter avec vous :) Pensez à enregistrer son numéro {NUMERO_AIRCALL_ACCOMPAGNANTE}\n A très bientôt !\nL'équipe 1001mots",
    "Bonjour,\nVous avez bien reçu le 1er livre de l’association 1001mots pour {PRENOM_ENFANT} ? {PRENOM_ACCOMPAGNANTE} va bientôt vous appeler pour en discuter avec vous et vous donner des astuces pour l'utiliser avec {PRENOM_ENFANT} ;) Pensez à enregistrer son numéro {NUMERO_AIRCALL_ACCOMPAGNANTE}\nA très bientôt !\nL'équipe 1001mots",
    "Bonjour,\nA 1001mots on espère que vous allez bien et {PRENOM_ENFANT} aussi :) {PRENOM_ACCOMPAGNANTE} va bientôt vous appeler pour prendre des nouvelles, discuter avec vous et vous donner des astuces pour aider {PRENOM_ENFANT} avec son langage.\nA très bientôt !\nL'équipe 1001mots",
    "Bonjour,\nA 1001mots on espère que vous allez bien et {PRENOM_ENFANT} aussi :) {PRENOM_ACCOMPAGNANTE} va bientôt vous appeler pour discuter avec vous de ce qui intéresse {PRENOM_ENFANT} en ce moment.\nA très bientôt !\nL'équipe 1001mots"
  ].freeze

  attr_reader :errors

  def initialize
    @errors = []
    @date = Time.zone.today
    @groups = []
    4.times do |time|
      @groups << Group.with_calls.where("call#{time}_start_date = ?", @date + 3.day)
    end
  end

  def call
    @groups.each_with_index do | group_list,call_index|
      group_list.each do |group|
        parent_ids = group
                       .child_supports
                       .joins(:supporter).where(supporter: { can_send_automatic_sms: true })
                       .previous_calls_ok_or_unfinished_before(call_index)
                       .map { |child_support| "parent.#{child_support.parent1.id}"}
        service = ProgramMessageService.new(
          @date.strftime('%d-%m-%Y'),
          '19:00',
          parent_ids,
          MESSAGE[call_index]
        ).call
        @errors << "Parent::SendDisengagementWarningBeforeCallsService (group: #{group.name}) : #{service.errors.uniq}" if service.errors
      end
    end
    self
  end
end
