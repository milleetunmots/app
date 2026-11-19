class Parent::IdentifyCalendlyInviteeService

  # prérempli par « Créer un rdv » quand le parent n'a pas d'e-mail
  PLACEHOLDER_EMAIL = 'rdv@1001mots.org'.freeze

  attr_reader :errors, :parent, :call_session

  def initialize(invitee_payload:)
    @errors = []
    @invitee_payload = invitee_payload
  end

  def call
    extract_tracking_info
    identify_by_token
    identify_by_event_type unless @parent || @errors.any?
    return self if @errors.any?
    return report_unidentified_parent unless @parent

    resolve_call_session
    self
  end

  private

  def extract_tracking_info
    tracking = @invitee_payload['tracking'] || {}
    @security_token = tracking['utm_content']&.gsub(/[^[:alnum:]]/, '')
    @utm_call_session = extract_call_session(tracking['utm_campaign'])
  end

  def extract_call_session(utm_campaign)
    return nil if utm_campaign.blank?

    match = utm_campaign.match(/call(\d+)/)
    match[1].to_i if match
  end

  # jeton absent, tronqué ou inconnu : on se rabat sur le lien réservé
  def identify_by_token
    return if @security_token.blank?

    @parent = Parent.kept.find_by(security_token: @security_token)
  end

  # chaque lien est un type d'événement one-off propre à un parent et à une session
  def identify_by_event_type
    return if event_type_uri.blank?

    link_parent = unique_parent_with_event_type
    return unless link_parent

    @parent = confirmed_family_parent(link_parent)
    report_unconfirmed_parent(link_parent) unless @parent
  end

  def unique_parent_with_event_type
    candidates = Parent.kept
                       .where('jsonb_exists(calendly_one_off_event_type_uris, ?)', event_type_uri)
                       .limit(2)
                       .to_a
    candidates.first if candidates.one?
  end

  # le lien a pu être transféré à l'autre parent de la fiche de suivi :
  # le RDV revient au parent qui l'a pris, en priorité celui du lien
  def confirmed_family_parent(link_parent)
    return link_parent if invitee_email.blank? && invitee_name_words.empty?

    family_parents(link_parent).find { |parent| email_matches?(parent) || last_name_matches?(parent) }
  end

  def family_parents(link_parent)
    child_support = link_parent.current_child&.child_support
    others = child_support ? [child_support.parent1, child_support.parent2] : []
    [link_parent, *others].compact.uniq.select(&:kept?)
  end

  def invitee_email
    email = @invitee_payload['email'].to_s.strip.downcase
    email unless email == PLACEHOLDER_EMAIL
  end

  def email_matches?(parent)
    invitee_email.present? && parent.email.to_s.strip.downcase == invitee_email
  end

  # le nom de famille entier doit figurer dans le nom saisi, espaces et tirets
  # ignorés : « Diallo-Sow » est reconnu dans « Mariam Diallo Sow » ou « DialloSow »
  def last_name_matches?(parent)
    last_name = name_words(parent.last_name).join
    return false if last_name.empty?

    words = invitee_name_words
    words.each_index.any? do |first|
      (first...words.size).any? { |last| words[first..last].join == last_name }
    end
  end

  def invitee_name_words
    @invitee_name_words ||= name_words(@invitee_payload['name'])
  end

  def name_words(name)
    I18n.transliterate(name.to_s).downcase.scan(/[a-z]+/)
  end

  # le lien réservé fait foi ; à défaut utm_campaign, puis les dates de la cohorte
  def resolve_call_session
    @call_session = link_call_session || @utm_call_session || call_session_from_event_date
  end

  def link_call_session
    return if event_type_uri.blank?

    family_parents(@parent).each do |parent|
      session = parent.calendly_one_off_event_type_uris&.dig(event_type_uri)
      return session if session
    end
    nil
  end

  # comme pour les appels Aircall : la session de la cohorte la plus proche de la date du RDV
  # (les dates propres à une accompagnante restent comprises dans celles de la cohorte)
  def call_session_from_event_date
    event_date = scheduled_event_date
    group = @parent.current_child&.group
    group.closest_call_session(event_date) if event_date && group
  end

  def scheduled_event_date
    start_time = scheduled_event['start_time']
    Time.zone.parse(start_time)&.to_date if start_time.present?
  rescue ArgumentError
    nil
  end

  def scheduled_event
    @invitee_payload['scheduled_event'] || {}
  end

  def event_type_uri
    scheduled_event['event_type']
  end

  def host_uris
    (scheduled_event['event_memberships'] || []).pluck('user')
  end

  # ni l'e-mail ni le nom saisis ne sont logués : données personnelles
  def report_unconfirmed_parent(link_parent)
    @errors << {
      message: 'Les informations saisies ne correspondent à aucun parent de la fiche de suivi du lien',
      context: { parent_id: link_parent.id, event_type_uri: event_type_uri, event_uri: @invitee_payload['event'] }
    }
  end

  def report_unidentified_parent
    @errors << {
      message: 'Aucun parent identifié pour ce RDV',
      context: {
        event_uri: @invitee_payload['event'],
        event_type_uri: event_type_uri,
        host_uris: host_uris,
        security_token: @security_token
      }
    }
    self
  end
end
