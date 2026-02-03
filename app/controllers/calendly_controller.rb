class CalendlyController < ApplicationController

  skip_before_action :authenticate_admin_user!
  skip_before_action :verify_authenticity_token
  before_action :verify_calendly_webhook_signature

  SHA256_ALGORITHM = OpenSSL::Digest.new('sha256').freeze
  CALENDLY_WEBHOOK_SIGNING_KEY = ENV['CALENDLY_WEBHOOK_SIGNING_KEY'].freeze

  INVITEE_CREATED_EVENT = 'invitee.created'.freeze
  INVITEE_CANCELED_EVENT = 'invitee.canceled'.freeze

  def webhooks
    event_type = params[:event]

    service = case event_type
              when INVITEE_CREATED_EVENT
                Calendly::ProcessInviteeCreatedService.new(payload: webhook_params).call
              when INVITEE_CANCELED_EVENT
                Calendly::ProcessInviteeCanceledService.new(payload: webhook_params).call
              else
                nil
              end

    if service&.errors&.any?
      Rollbar.error(
        'Calendly webhook service error',
        service: service.class.to_s,
        errors: service.errors,
        event: event_type,
        payload: webhook_params
      )
    end

    head :ok
  end

  private

  def verify_calendly_webhook_signature
    return handle_missing_signing_key if CALENDLY_WEBHOOK_SIGNING_KEY.blank?

    request.body.rewind
    request_body = request.body.read

    received_signature = request.env['HTTP_CALENDLY_WEBHOOK_SIGNATURE']
    return handle_unverified_request if received_signature.nil?

    timestamp, signature = parse_signature_header(received_signature)
    return handle_unverified_request unless timestamp && signature

    return handle_expired_timestamp(timestamp) if timestamp_expired?(timestamp)

    expected_signature = compute_signature(timestamp, request_body)
    return if Rack::Utils.secure_compare(expected_signature, signature)

    handle_unverified_request
  end

  def parse_signature_header(header)
    parts = header.split(',').to_h { |part| part.split('=', 2) }
    timestamp = parts['t']
    signature = parts['v1']
    [timestamp, signature]
  rescue StandardError
    [nil, nil]
  end

  def compute_signature(timestamp, body)
    data = "#{timestamp}.#{body}"
    OpenSSL::HMAC.hexdigest(SHA256_ALGORITHM, CALENDLY_WEBHOOK_SIGNING_KEY, data)
  end

  def timestamp_expired?(timestamp, tolerance: 1000)
    webhook_time = Time.zone.at(timestamp.to_i)
    (Time.zone.now - webhook_time).abs > tolerance
  end

  def handle_missing_signing_key
    Rollbar.error('Calendly webhook signing key not configured')
    head :internal_server_error
  end

  def handle_unverified_request
    Rollbar.error('Calendly webhook with bad signature', payload: params.to_unsafe_h)
    head :unauthorized
  end

  def handle_expired_timestamp(timestamp)
    Rollbar.error('Calendly webhook with expired timestamp', timestamp: timestamp)
    head :unauthorized
  end

  def webhook_params
    params.to_unsafe_h.except(:controller, :action)
  end
end
