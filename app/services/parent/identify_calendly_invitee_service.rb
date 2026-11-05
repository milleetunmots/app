class Parent::IdentifyCalendlyInviteeService

  # longueur d'un security_token (SecureRandom.hex(16)) : en dessous, le lien a été tronqué
  FULL_TOKEN_LENGTH = 32

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
    identify_by_contact unless @parent
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

  # chaque lien est un type d'événement one-off propre à un parent et à une session,
  # retrouvable même quand les paramètres utm ont été retirés du lien
  def identify_by_event_type
    byebug
    event_type_uri = scheduled_event['event_type']
    return if event_type_uri.blank?

    candidates = Parent.kept
                       .where('jsonb_exists(calendly_one_off_event_type_uris, ?)', event_type_uri)
                       .limit(2)
                       .to_a
    return unless candidates.one?

    @parent = candidates.first
    @call_session = @parent.calendly_one_off_event_type_uris[event_type_uri]
  end

  def identify_by_contact
    return unless host_uris.one?

    match = Parent::MatchCalendlyInviteeContactService.new(
      host_calendly_user_uri: host_uris.first,
      email: @invitee_payload['email'],
      name: @invitee_payload['name']
    ).call
    @errors.concat(match.errors)
    assign_current_call_session(match.parent) if match.parent
  end

  # le lien ne dit rien de la session : on retient celle en cours, SMS de RDV envoyé à J-3
  def assign_current_call_session(parent)
    call_session = parent.current_child&.child_support&.active_call_index(days_before: 3)
    if call_session.nil?
      @errors << { message: "Aucune session d'appel en cours pour ce parent", context: { parent_id: parent.id } }
      return
    end

    @parent = parent
    @call_session = call_session
  end

  def scheduled_event
    @invitee_payload['scheduled_event'] || {}
  end

  def host_uris
    (scheduled_event['event_memberships'] || []).pluck('user')
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
