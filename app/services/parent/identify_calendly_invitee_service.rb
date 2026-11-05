class Parent::IdentifyCalendlyInviteeService

  attr_reader :errors, :parent, :call_session

  def initialize(invitee_payload:)
    @errors = []
    @invitee_payload = invitee_payload
  end

  def call
    extract_tracking_info
    return self if @errors.any?

    find_parent
    self
  end

  private

  def extract_tracking_info
    tracking = @invitee_payload['tracking'] || {}
    @security_token = tracking['utm_content']&.gsub(/[^[:alnum:]]/, '')
    @call_session = extract_call_session(tracking['utm_campaign'])

    return if @security_token.present?

    @errors << {
      message: 'Le security_token (utm_content) est manquant dans le payload',
      tracking: tracking
    }
  end

  def extract_call_session(utm_campaign)
    return nil if utm_campaign.blank?

    match = utm_campaign.match(/call(\d+)/)
    match[1].to_i if match
  end

  def find_parent
    @parent = Parent.find_by(security_token: @security_token)

    return if @parent

    @errors << {
      message: 'Aucun parent trouvé avec le security_token',
      security_token: @security_token
    }
  end
end
