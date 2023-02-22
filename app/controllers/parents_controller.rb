class ParentsController < ApplicationController

  def current_child
    if params[:id]
      response = Parent.find(params[:id]).current_child || {}
      render json: response.to_json
    end
  end
end

