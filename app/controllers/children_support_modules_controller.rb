class ChildrenSupportModulesController < ApplicationController

  before_action :find_children_support_module, only: %i[edit update]

  def edit
    @support_modules = @children_support_module.available_support_modules

    @action_path = children_support_module_path(@children_support_module, security_code: @children_support_module.parent.security_code)
  end

  def update
    if @children_support_module.update(children_support_module_params)
      redirect_to updated_children_support_modules_path
    else
      render action: :edit
    end
  end

  def updated; end

  private

  def children_support_module_params
    params.require(:children_support_module).permit(:support_module_id)
  end

  def find_children_support_module
    @children_support_module = ChildrenSupportModule.find_by(id: params[:id])
    not_found and return if @children_support_module.nil?
    not_found and return if @children_support_module.parent.security_code != params[:security_code]
  end
end
