class ParentsController < ApplicationController
  def first_child
    if params[:id]
      response = Parent.find(params[:id]).first_child || {}
      render json: response.to_json
    end
  end
end

