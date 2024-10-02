class TypeformController < ApplicationController
  skip_before_action :authenticate_admin_user!
  skip_before_action :verify_authenticity_token

  def webhooks
    byebug
    case params[:form_response][:form_id]
    when 'YzlXcWSJ'
      Typeform::MidwayFormService.new(params[:form_response]).call
    when 'swkzdIlg', 'dZCvik1O'
      Typeform::Call3FormService.new(params[:form_response]).call
    when 'aBALISn7'
      Typeform::Call0FormService.new(params[:form_response]).call
    else
      Typeform::InitialFormService.new(params[:form_response]).call
    end
  end
end
