class TypeformController < ApplicationController
  skip_before_action :authenticate_admin_user!
  skip_before_action :verify_authenticity_token

  def webhooks
    case params[:form_response][:form_id]
    when 'YzlXcWSJ'
      Typeform::MidwayFormService.new(params[:form_response]).call
    when 'swkzdIlg', 'dZCvik1O', 'aBALISn7'
      Typeform::CallGoalsFormService.new(params[:form_response]).call
    else
      Typeform::InitialFormService.new(params[:form_response]).call
    end
  end
end
