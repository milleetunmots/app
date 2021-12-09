class ParentsController < ApplicationController

  skip_before_action :verify_authenticity_token

  def first_child
    if params[:id]
      response = Parent.find(params[:id]).first_child || {}
      render json: response.to_json
    end
  end

  def new_welcome_form_response
    service = Typeform::GetResponses.new.call
    redirect_to admin_parents_path
  end
end

