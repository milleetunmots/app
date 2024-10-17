class TypeformController < ApplicationController
  skip_before_action :authenticate_admin_user!
  skip_before_action :verify_authenticity_token

  def webhooks
    case params[:form_response][:form_id]
    when 'YzlXcWSJ'
      Typeform::MidwayFormService.new(params[:form_response]).call
    when 'aBALISn7'
      Typeform::CallGoalsFormService.new(params[:form_response], 0).call
    when 'swkzdIlg', 'dZCvik1O'
      Typeform::CallGoalsFormService.new(params[:form_response], 3).call
    when 'XdWSv2hR'
      Typeform::InitialFormService.new(params[:form_response]).call
    else
      Rollbar.error("Typeform with unknown id: #{params[:form_response][:form_id]}")
    end
  end
end
