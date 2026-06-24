class Parent::SendBeforeCallsMessageDailyService

  SMS_OFFSET_DAYS = 3
  CALL_SESSIONS = [0, 1, 2, 3].freeze

  attr_reader :errors

  def initialize(date: Time.zone.today)
    @errors = []
    @date = date
  end

  def call
    if ENV['BETA_TEST_CALLERS_EMAIL'].blank?
      @errors << { service: 'Parent::SendBeforeCallsMessageDailyService', error: 'BETA_TEST_CALLERS_EMAIL is not set' }
      return self
    end

    CALL_SESSIONS.each do |call_session|
      recipients = recipients_for_call(call_session)
      next if recipients.empty?

      recipients
        .group_by { |r| r[:child_support].current_child&.group }
        .each do |group, group_recipients|
          next if group.nil?

          child_support_ids = group_recipients.map { |r| r[:child_support].id }.uniq
          dispatch(group, call_session, child_support_ids)
        end
    end

    self
  end

  private

  def target_start_date
    @date + SMS_OFFSET_DAYS.days
  end

  # Destinataires du message initial de prise de RDV à envoyer aujourd'hui :
  # le début effectif de la plage est à J+SMS_OFFSET_DAYS ou moins (cas nominal
  # J-3 ; si un run quotidien a sauté, on rattrape tant que la plage n'est pas
  # finie, la déduplication par calendly_initial_booking_dates évite les doublons).
  def recipients_for_call(call_index)
    candidate_child_supports(call_index).flat_map do |child_support|
      start_date = child_support.call_session_start_date(call_index)
      end_date = child_support.call_session_end_date(call_index)
      next [] unless start_date.present? && start_date <= target_start_date
      next [] unless end_date.present? && end_date >= @date

      parents_awaiting_initial_message(child_support, call_index, start_date).map do |parent|
        { parent: parent, child_support: child_support, call_index: call_index }
      end
    end
  end

  # Familles accompagnées par une beta-testeuse dont la fenêtre de session de
  # cohorte peut contenir une plage effective éligible. Un override reste
  # forcément dans la fenêtre de session de sa cohorte, donc ce filtre SQL est
  # un sur-ensemble des plages effectives affinées en Ruby ci-dessus.
  def candidate_child_supports(call_index)
    ChildSupport
      .kept
      .with_valid_supporter_for_calendly
      .where(supporter: { email: ENV['BETA_TEST_CALLERS_EMAIL'].split })
      .where("groups.call#{call_index}_start_date <= ?", target_start_date)
      .where("groups.call#{call_index}_end_date >= ?", @date)
      .where("child_supports.call#{call_index}_status IS NULL OR child_supports.call#{call_index}_status = ''")
      .includes(:supporter, :current_child, :parent1, :parent2)
      .distinct
  end

  # Parents à contacter, sauf ceux qui ont déjà reçu leur 1er message pour cette session.
  def parents_awaiting_initial_message(child_support, call_index, session_start_date)
    current_child = child_support.current_child
    return [] unless current_child

    [
      (child_support.parent1 if current_child.should_contact_parent1?),
      (child_support.parent2 if current_child.should_contact_parent2?)
    ].compact.reject do |parent|
      initial_message_sent_for_current_session?(parent, call_index, session_start_date)
    end
  end

  # Le 1er message est considéré comme déjà envoyé seulement si sa date tombe
  # dans la fenêtre d'envoi de la session en cours (>= début effectif - 3
  # jours) : une date issue d'un accompagnement précédent (même session
  # d'appel, 1-2 ans plus tôt) ne doit pas bloquer le nouvel accompagnement.
  def initial_message_sent_for_current_session?(parent, call_index, session_start_date)
    raw = parent.calendly_initial_booking_dates&.dig("call#{call_index}")
    return false if raw.blank?

    sent_on =
      begin
        raw.to_date
      rescue ArgumentError, TypeError
        # Valeur illisible : on considère le message envoyé pour ne pas risquer
        # un envoi quotidien en boucle (la date ne serait jamais rafraîchie).
        return true
      end

    sent_on >= session_start_date - SMS_OFFSET_DAYS.days
  end

  def dispatch(group, call_session, child_support_ids)
    if call_session.zero?
      service = Parent::SendBeforeFirstCallMessageService.new(group_id: group.id, date: @date)
      service.handle_group_message(group, child_support_ids)
    else
      service = Parent::SendBeforeCallsMessageService.new(date: @date)
      service.handle_group_message(group, call_session, child_support_ids)
    end

    @errors.concat(service.errors) if service.errors.any?
  end
end
