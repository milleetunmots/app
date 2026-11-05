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

    report_unidentified_parent
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

  def report_unidentified_parent
    scheduled_event = @invitee_payload['scheduled_event'] || {}
    @errors << {
      message: 'Aucun parent identifié pour ce RDV',
      context: {
        event_uri: @invitee_payload['event'],
        event_type_uri: scheduled_event['event_type'],
        host_uris: (scheduled_event['event_memberships'] || []).pluck('user'),
        security_token: @security_token
      }
    }
  end
end
