class ParentsController < ApplicationController

  before_action :find_child, only: %i[edit update]

  def first_child
    if params[:id]
      response = Parent.find(params[:id]).first_child || {}
      render json: response.to_json
    end
  end

  def edit
    @available_module_list = @parent.available_module_list
    @action_path = update_parent_path(parent_id: @parent.id, security_code: @parent.security_code)
  end

  def update
    selected_module = params.require(:parent).permit(:selected_module)
    @parent.selected_module_list.add selected_module.values
    if @parent.save(validate: false)
      redirect_to updated_parent_path
    else
      render action: :edit
    end
  end

  private

  def find_child
    @parent = Parent.where(id: params[:parent_id], security_code: params[:security_code]).first

    head 404 and return if @parent.nil?
  end
end

