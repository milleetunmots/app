class TypeformController < ApplicationController
  skip_before_action :verify_authenticity_token

  def webhooks
    Typeform::InitialFormService.new(params[:form_response]).call
  end
end
