class ParentsController < ApplicationController

  def current_child
    response = Parent.find_by(id: params[:id])&.current_child || {}
    render json: response.to_json
  end

  def update
    head :no_content
    parent_attributes = params.require(:parent).permit(:mid_term_rate, :mid_term_reaction, :mid_term_speech)
    parent = Parent.find(params[:id])
    parent.attributes = parent_attributes
    parent.save(validate: false)
  end
end
