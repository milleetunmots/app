class ParentsController < ApplicationController

  def current_child_source
    current_child = Parent.find_by(id: params[:id])&.current_child
    render json: {} unless current_child

    source = current_child.children_source&.source_id
    source_details = current_child.children_source&.details
    response = { group_id: current_child.group_id, source: source, source_details: source_details }
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
