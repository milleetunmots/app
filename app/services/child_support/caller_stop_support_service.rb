class ChildSupport::CallerStopSupportService

  PROGRAM_TERMINATION_MESSAGE = <<~MESSAGE.freeze
    Bonjour, Votre accompagnement 1001mots s'arrête. Pour des raisons techniques, vous allez recevoir encore quelques SMS, répondez STOP si vous voulez les arrêter.
    Si vous avez quelques minutes pour nous faire un retour sur 1001mots, ce serait très utile : https://form.typeform.com/to/oy3wjinA#st=xxxxx
  MESSAGE
  PARTNER_REFERRAL_REQUIRED_MESSAGE = <<~MESSAGE.freeze
    1001mots: Merci de l'intérêt que vous portez à l'association ! Le programme est réservé aux familles adressées par nos partenaires, nous devons donc mettre fin à l’accompagnement.
    Si vous êtes un.e professionnel de PMI, écrivez-nous à l’adresse pmi@1001mots.org.
  MESSAGE
  LANGUAGE_BARRIER_TERMINATION_MESSAGE = <<~MESSAGE.freeze
    1001mots : Bonjour, votre accompagnement s’arrête. Nous sommes désolés de ne pas pouvoir vous accompagner dans votre langue...
    Voici une playlist Youtube de vidéos dans plein de langues, il y aura peut-être la vôtre : https://www.youtube.com/@papotoparentalitepourtous7726/playlists
  MESSAGE

  STOP_SUPPORT_INFORMATIONS = {
    program: { tag: 'arrêt accompagnante - programme', sms: PROGRAM_TERMINATION_MESSAGE, motive: 'la famille ne veut pas du programme complet' },
    very_advanced_practices: { tag: 'arrêt accompagnante - pratiques parentales avancées', sms: PROGRAM_TERMINATION_MESSAGE, motive: 'la famille a des pratiques très avancées' },
    problematic_case: { tag: 'arrêt accompagnante - problèmes', sms: PROGRAM_TERMINATION_MESSAGE, motive: 'la famille me pose problème (insulte, propos gênants, raccroche au nez, etc)' },
    professional: { tag: 'arrêt accompagnante - pro de santé', sms: PARTNER_REFERRAL_REQUIRED_MESSAGE, motive: "La famille est un.e professionnel.le de santé qui souhaite tester l'accompagnement" },
    registered_by_partner_without_consent: { tag: 'arrêt accompagnante - inscription sans accord', sms: PROGRAM_TERMINATION_MESSAGE, motive: 'la famille a été inscrite par un partenaire sans son accord' },
    family_limited_french_for_support: { tag: 'arrêt accompagnante - non francophone', sms: LANGUAGE_BARRIER_TERMINATION_MESSAGE, motive: "la famille n'est pas assez francophone pour tirer profit de l’accompagnement" },
    family_unresponsive_after_adaptation: { tag: 'arrêt accompagnante - sans résultat', sms: LANGUAGE_BARRIER_TERMINATION_MESSAGE, motive: "je vois que la famille ne me répond plus / j'ai des doutes sur l'impact du programme" }
  }.freeze

  attr_reader :error

  def initialize(supporter_id, child_support_id, reason, details)
    @supporter = AdminUser.find(supporter_id)
    @child_support = ChildSupport.find(child_support_id)
    @reason = reason
    @details = details
    @error = nil
  end

  def call
    ActiveRecord::Base.transaction do
      add_stop_support_informations
      stop_support
      add_tag
      send_message
    end
    self
  end

  private

  def add_stop_support_informations
    byebug
    @child_support.stop_support_caller_id = @supporter.id
    @child_support.stop_support_reason = STOP_SUPPORT_INFORMATIONS[@reason.to_sym][:motive]
    @child_support.stop_support_date = DateTime.now
    @child_support.stop_support_details = @details
    @error = "Les informations n'ont pas pu être ajoutée à la fiche de suivie" unless @child_support.save
    raise ActiveRecord::Rollback unless @error.nil?
  end

  def stop_support
    @child_support.children.each do |child|
      if child.group.present?
        child.group_status = 'stopped'
        child.group_end = Time.zone.today
      else
        child.group_status = 'not_supported'
      end
      @error = "L'accompagnement de #{child.first_name} n'a pas pu être arrêté" unless child.save
      raise ActiveRecord::Rollback unless @error.nil?
    end
    @child_support.important_information =
      "#{@child_support.important_information}\nAccompagnement arrêté le #{DateTime.now.strftime('%d/%m/%Y')} pour le motif \"#{STOP_SUPPORT_INFORMATIONS[@reason.to_sym][:motive]}\" à la demande de #{@supporter.name}"
    @child_support.save
  end

  def add_tag
    @child_support.tag_list += [STOP_SUPPORT_INFORMATIONS[@reason.to_sym][:tag]].flatten
    @child_support.save!
    @error = "Le tag n'a pas pu être ajouté à la fiche de suivi" unless @child_support.save
    raise ActiveRecord::Rollback unless @error.nil?
  end

  def send_message
    @message = STOP_SUPPORT_INFORMATIONS[@reason.to_sym][:sms].dup
    errors_count = 0
    recipients.each do |recipient|
      program_message_service = ProgramMessageService.new(
        DateTime.now.strftime('%Y-%m-%d'),
        DateTime.now.strftime('%H:%M'),
        [recipient],
        @message,
        nil,
        nil,
        nil,
        nil,
        nil,
        Child::GROUP_STATUS
      ).call
      if program_message_service.errors.any?
        errors_count += 1
        @error = program_message_service.errors.join("\n")
      end
    end
    errors_count == recipients.size ? raise(ActiveRecord::Rollback) : @error = nil
  end

  def recipients
    recipients = []
    recipients << "parent.#{@child_support.parent1.id}" if @child_support.parent1.should_be_contacted?
    return recipients if @child_support.parent2.nil?

    recipients << "parent.#{@child_support.parent2.id}" if @child_support.parent2.should_be_contacted?
    recipients
  end
end
