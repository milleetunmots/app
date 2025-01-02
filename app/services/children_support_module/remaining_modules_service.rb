class ChildrenSupportModule::RemainingModulesService
  attr_reader :max_remaining_module_count, :remaining_module_count, :module_index, :errors

  def initialize(parent_id:, group_id:, children_support_module:)
    @parent_id = parent_id
    @group_id = group_id
    @children_support_module = children_support_module
    @errors = []
  end

  def call
    current_child = Parent.find(@parent_id).current_child
    @module_index = @children_support_module.module_index
    group = Group.find(@group_id)
    group_support_modules_count = group.support_modules_count
    @max_remaining_module_count = group_support_modules_count - @module_index
    @remaining_module_count = 0

    select_module_date =
      case @module_index
      when 3
        current_child.group.started_at + 10.weeks
      else
        (current_child.group.started_at + ((@module_index - 2) * 8.weeks)).next_occurring(:monday)
      end

    1.upto(@max_remaining_module_count) do |count|
      break if select_module_date + (count * (count == 1 && @module_index == 3 ? 7.weeks : 8.weeks)) >= current_child.birthdate + 36.months

      @remaining_module_count += 1
    end

    self
  end
end
