class TypeformController < ApplicationController
  skip_before_action :authenticate_admin_user!
  skip_before_action :verify_authenticity_token
  before_action :verify_typeform_webook_token

  SHA256_ALGORITHM = OpenSSL::Digest.new('sha256').freeze
  SIGNATURE_PREFIX = 'sha256='.freeze
  TYPEFORM_WEBHOOKS_SECRET_TOKEN = ENV['TYPEFORM_WEBHOOKS_SECRET_TOKEN'].freeze
  MIDWAY_TYPEFORM_ID = ENV['MIDWAY_TYPEFORM_ID'].freeze
  CALL_ZERO_GOALS_TYPEFORM_ID = ENV['CALL_ZERO_GOALS_TYPEFORM_ID'].freeze
  CALL_THREE_SPEAKING_TYPEFORM_ID = ENV['CALL_THREE_SPEAKING_TYPEFORM_ID'].freeze
  CALL_THREE_OBSERVING_TYPEFORM_ID = ENV['CALL_THREE_OBSERVING_TYPEFORM_ID'].freeze
  INITIAL_TYPEFORM_ID = ENV['INITIAL_TYPEFORM_ID'].freeze
  UPDATING_ADDRESS_TYPEFORM_ID = ENV['UPDATING_ADDRESS_TYPEFORM_ID'].freeze
  UPSTREAM_ADDRESS_UPDATING_TYPEFORM_ID = ENV['UPSTREAM_ADDRESS_UPDATING_TYPEFORM_ID'].freeze
  TYPEFORM_IDS = [
    MIDWAY_TYPEFORM_ID,
    CALL_ZERO_GOALS_TYPEFORM_ID,
    CALL_THREE_SPEAKING_TYPEFORM_ID,
    CALL_THREE_OBSERVING_TYPEFORM_ID,
    INITIAL_TYPEFORM_ID,
    UPDATING_ADDRESS_TYPEFORM_ID,
    UPSTREAM_ADDRESS_UPDATING_TYPEFORM_ID
  ].freeze

  def webhooks
    if params[:form_response][:form_id].in? TYPEFORM_IDS
      service =
        case params[:form_response][:form_id]
        when MIDWAY_TYPEFORM_ID
          Typeform::MidwayFormService.new(params[:form_response]).call
        when CALL_ZERO_GOALS_TYPEFORM_ID
          Typeform::CallGoalsFormService.new(params[:form_response], 0).call
        when CALL_THREE_SPEAKING_TYPEFORM_ID, CALL_THREE_OBSERVING_TYPEFORM_ID
          Typeform::CallGoalsFormService.new(params[:form_response], 3).call
        when INITIAL_TYPEFORM_ID
          Typeform::InitialFormService.new(params[:form_response]).call
        when UPDATING_ADDRESS_TYPEFORM_ID, UPSTREAM_ADDRESS_UPDATING_TYPEFORM_ID
          Typeform::UpdateAddressService.new(params[:form_response]).call
        end
      Rollbar.error('Typeform service error', service: service.class.to_s, errors: service.errors, form_response: params[:form_response]) unless service.errors.empty?
    else
      Rollbar.error('Typeform with unknown id', typeform_id: params[:form_response][:form_id], form_response: params[:form_response])
    end

    head :ok
  end

  private

  def verify_typeform_webook_token
    request.body.rewind
    request_body = request.body.read
    handle_empty_request_body && return if request_body.empty?

    received_signature = request.env['HTTP_TYPEFORM_SIGNATURE']
    handle_unverified_request && return if received_signature.nil?

    hash = OpenSSL::HMAC.digest(SHA256_ALGORITHM, TYPEFORM_WEBHOOKS_SECRET_TOKEN, request_body)
    actual_signature = SIGNATURE_PREFIX + Base64.strict_encode64(hash)
    return if Rack::Utils.secure_compare(actual_signature, received_signature)

    handle_unverified_request
  end

  def handle_unverified_request
    Rollbar.error('Typeform webhook with bad signature', form_response: params[:form_response])
    head :internal_server_error
  end

  def handle_empty_request_body
    Rollbar.error('Typeform webhook received with an empty request body', form_response: params[:form_response])
    head :bad_request
  end
end
