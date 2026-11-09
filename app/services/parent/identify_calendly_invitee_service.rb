class Parent::IdentifyCalendlyInviteeService

  # longueur d'un security_token (SecureRandom.hex(16)) : en dessous, le lien a été tronqué
  FULL_TOKEN_LENGTH = 32

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
    return self if @parent || @errors.any?

    identify_by_event_type
    report_unidentified_parent unless @parent || @errors.any?
    self
  end

  private

  def extract_tracking_info
    tracking = @invitee_payload['tracking'] || {}
    @security_token = tracking['utm_content']&.gsub(/[^[:alnum:]]/, '')
    @call_session = extract_call_session(tracking['utm_campaign'])
  end

  def extract_call_session(utm_campaign)
    return nil if utm_campaign.blank?

    match = utm_campaign.match(/call(\d+)/)
    match[1].to_i if match
  end

  def identify_by_token
    return if @security_token.blank?

    if @security_token.length >= FULL_TOKEN_LENGTH
      find_parent_by_full_token
    else
      find_parent_by_token_prefix
    end
  end

  # un jeton complet inconnu n'est pas un lien abîmé : pas de repli sur les autres moyens
  def find_parent_by_full_token
    @parent = Parent.find_by(security_token: @security_token)

    return if @parent

    @errors << {
      message: 'Aucun parent trouvé avec le security_token',
      security_token: @security_token
    }
  end

  def find_parent_by_token_prefix
    candidates = Parent.kept
                       .where('security_token LIKE ?', "#{Parent.sanitize_sql_like(@security_token)}%")
                       .limit(2)
                       .to_a
    @parent = candidates.first if candidates.one?
  end

  # chaque lien est un type d'événement one-off propre à un parent et à une session
  def identify_by_event_type
    event_type_uri = scheduled_event['event_type']
    return if event_type_uri.blank?

    candidate = unique_parent_with_event_type(event_type_uri)
    return unless candidate

    unless invitee_confirms?(candidate)
      report_unconfirmed_parent(candidate, event_type_uri)
      return
    end

    @parent = candidate
    @call_session = candidate.calendly_one_off_event_type_uris[event_type_uri]
  end

  def unique_parent_with_event_type(event_type_uri)
    candidates = Parent.kept
                       .where('jsonb_exists(calendly_one_off_event_type_uris, ?)', event_type_uri)
                       .limit(2)
                       .to_a
    candidates.first if candidates.one?
  end

  # sans e-mail ni nom saisis, le lien suffit
  def invitee_confirms?(parent)
    return true if invitee_email.blank? && invitee_name_words.empty?

    email_matches?(parent) || name_word_matches?(parent)
  end

  def invitee_email
    email = @invitee_payload['email'].to_s.strip.downcase
    email unless email == PLACEHOLDER_EMAIL
  end

  def email_matches?(parent)
    invitee_email.present? && parent.email.to_s.strip.downcase == invitee_email
  end

  def name_word_matches?(parent)
    invitee_name_words.intersect?(name_words("#{parent.first_name} #{parent.last_name}"))
  end

  def invitee_name_words
    name_words(@invitee_payload['name'])
  end

  def name_words(name)
    I18n.transliterate(name.to_s).downcase.scan(/[a-z]+/)
  end

  def scheduled_event
    @invitee_payload['scheduled_event'] || {}
  end

  def host_uris
    (scheduled_event['event_memberships'] || []).pluck('user')
  end

  # ni l'e-mail ni le nom saisis ne sont logués : données personnelles
  def report_unconfirmed_parent(parent, event_type_uri)
    @errors << {
      message: 'Les informations saisies ne correspondent pas au parent du lien',
      context: { parent_id: parent.id, event_type_uri: event_type_uri, event_uri: @invitee_payload['event'] }
    }
  end

  def report_unidentified_parent
    @errors << {
      message: 'Aucun parent identifié pour ce RDV',
      context: {
        event_uri: @invitee_payload['event'],
        event_type_uri: scheduled_event['event_type'],
        host_uris: host_uris,
        security_token: @security_token
      }
    }
  end
end
