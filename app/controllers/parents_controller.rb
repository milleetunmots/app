class ParentsController < ApplicationController
  def first_child
    if params[:id]
      parent = Parent.find(params[:id])
      render json: parent.first_child.to_json
    end
  end
end
