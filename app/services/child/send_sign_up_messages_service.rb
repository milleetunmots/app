class Child::SendSignUpMessagesService

  def initialize(child, registration_origin)
    @child = child
    @registration_origin = registration_origin
  end

  def call
    send_form_by_sms
    send_not_supported_sms
    send_instagram_message
    self
  end

  private

  # Inscription refusée, quel qu'en soit le motif : ni le SMS de bienvenue ni
  # le lien vers le questionnaire ne doivent partir. `SendInitialFormSmsJob` ne
  # consulte pas `group_status`, c'est donc ici que la garde doit vivre.
  def registration_rejected?
    'filtre-diplome-KO'.in?(@child.tag_list) || @child.group_status == 'not_supported'
  end

  def send_form_by_sms
    return if registration_rejected?
    return if @child.child_support.enrollment_reasons.any?

    if eval25_registration?
      report_message_errors(registration_messages.call(:eval25), 'SMS eval25')
    elsif delayed_questionnaire?
      Child::SendInitialFormSmsJob.set(wait: 2.hours).perform_later(@child.parent1_id)
    end

    report_message_errors(registration_messages.send_questionnaire(at: Time.zone.now.change(hour: 18)), 'SMS formulaire initial') if @registration_origin.in?([3, 5])
  end

  def eval25_registration?
    ENV['EVAL25'].present? && @child.source.name == ENV['CAF93']
  end

  def delayed_questionnaire?
    @registration_origin == 4 || (@registration_origin == 2 && ENV['CAF_SUBSCRIPTION'].nil?)
  end

  def send_not_supported_sms
    return unless @registration_origin == 4 && 'filtre-diplome-KO'.in?(@child.tag_list)

    report_message_errors(Child::ProgramNotSupportedMessageService.new(@child).call, 'SMS non accompagnement')
  end

  def send_instagram_message
    return unless @child.group_status.in? %w[active waiting]

    service = registration_messages.call(
      ENV['CAF_SUBSCRIPTION'].present? ? :instagram_caf : :instagram,
      at: Time.zone.now.advance(days: 3).change(hour: 18), variables: { 'PRENOM_ENFANT' => @child.first_name }
    )
    report_message_errors(service, 'SMS Instagram')
  end

  def registration_messages
    Child::ProgramRegistrationMessagesService.new(@child.parent1)
  end

  # Ces envois sont en « fire and forget » : sans cette remontée, une panne du
  # fournisseur (réponse non-JSON) se solde par un SMS perdu en silence.
  def report_message_errors(service, context)
    return if service.errors.blank?

    Rollbar.error("Child::CreateService — #{context} non envoyé : #{service.errors}", child_id: @child.id, parent_id: @child.parent1_id)
  end
end
