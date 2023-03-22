class ChildrenSupportModulesController < ApplicationController

  before_action :find_children_support_module, only: %i[edit update]

  def edit
    @child_name = @children_support_module.child.first_name
    @support_modules = @children_support_module.available_support_modules
    @action_path = children_support_module_path(@children_support_module, sc: @children_support_module.parent.security_code)
  end

  def update
    @children_support_module.choice_date = Date.today
    @children_support_module.is_completed = true

    if @children_support_module.update(children_support_module_params)
      redirect_to updated_children_support_modules_path(child_first_name: @children_support_module.child.first_name )
    else
      @support_modules = @children_support_module.available_support_modules
      @action_path = children_support_module_path(@children_support_module, sc: @children_support_module.parent.security_code)
      render action: :edit
    end
  end

  def updated
    @child_first_name = params[:child_first_name]
  end

  private

  def children_support_module_params
    params.require(:children_support_module).permit(:support_module_id)
  end

  def find_children_support_module
    @security_code = params[:sc] || params[:security_code]
    @children_support_module = ChildrenSupportModule.find_by(id: params[:id])
    not_found and return if @children_support_module.nil?
    not_found and return if @children_support_module.parent.security_code != @security_code
  end
end
