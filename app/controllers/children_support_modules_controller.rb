class ChildrenSupportModulesController < ApplicationController
  skip_before_action :authenticate_admin_user!
  before_action :find_children_support_module, only: %i[edit update updated]

  def edit
    @support_module_selected = @children_support_module.support_module
    @support_modules = @children_support_module.available_support_modules.map(&:decorate)
    @action_path = children_support_module_path(@children_support_module, sc: @children_support_module.parent.security_code)
  end

  def update
    @children_support_module.choice_date = Time.zone.today
    @children_support_module.is_completed = true

    if @children_support_module.update(children_support_module_params)
      group_id = @children_support_module.child.group_id
      child_support_id = @children_support_module.child.child_support_id
      if @children_support_module.module_index.eql?(6)
        # redirect to feedback form
        survey = Survey.find_by(name: ENV['SURVEY_NAME_MODULE_FIVE_BOOKS'])
        redirect_to new_survey_parent_answer_path(
          survey,
          @children_support_module.parent,
          sc: @children_support_module.parent.security_code,
          child_id: @children_support_module.child_id
        )
      else
        redirect_to updated_children_support_module_path(
          @children_support_module.id,
          child_first_name: @children_support_module.child.first_name,
          sc: @children_support_module.parent.security_code,
          group_id: group_id,
          child_support_id: child_support_id
        )
      end
    else
      @support_modules = @children_support_module.available_support_modules
      @action_path = children_support_module_path(@children_support_module, sc: @children_support_module.parent.security_code)
      render action: :edit
    end
  end

  def updated
    # link only for third choice
    @module_three = @children_support_module.child.group.with_module_zero? ? @children_support_module.module_index.eql?(4) : @children_support_module.module_index.eql?(3)
    @parent_id = @children_support_module.parent_id
    @typeform_link = "https://wr1q9w7z4ro.typeform.com/to/#{ENV['MIDWAY_TYPEFORM_ID']}#st=#{@children_support_module.parent.security_token}"
    @group_id = params[:group_id]
    @child_first_name = params[:child_first_name]
    calc_service = ChildrenSupportModule::RemainingModulesService.new(
      parent_id: @parent_id,
      group_id: @group_id,
      children_support_module: @children_support_module
    ).call

    @max_remaining_module_count = calc_service.max_remaining_module_count
    @remaining_module_count = calc_service.remaining_module_count
    @module_index = calc_service.module_index
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
