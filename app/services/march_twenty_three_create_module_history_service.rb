class MarchTwentyThreeCreateModuleHistoryService

  attr_reader :module_history

  def initialize
    @group = Group.find(53)
    @module_history = {}
  end

  def call
    @group.children.where(group_status: 'active').each do |child|
      choices = child.children_support_modules.where(is_programmed: true).where.not(support_module: nil).order(:created_at).group_by {|record| record.created_at.to_date }

      # only retrieve choices programmed, grouped by dates so we can clearly understand
      # which support module choice it is
      choices.each_with_index do |(k,v),index|
        # check if there are duplicate choice (should only be the case with multiple parents)
        # if yes, only pick one of them to avoid duplicate (ie. 2 parents with the same choice)
        same_choice = v.all? { |csm| csm.support_module_id == v.first.support_module_id }
        if same_choice
          choice = v.find { |record| record.is_completed } || v.first
          support_module_name = choice.support_module.decorate.name_with_tags.parameterize.to_sym
          add_choice_to_hash(support_module_name, index, choice.is_completed)
        else
          # if the choices are different, then we count them all (different module chosen for each parent)
          v.each do |choice|
            support_module_name = choice.support_module.decorate.name_with_tags.parameterize.to_sym
            add_choice_to_hash(support_module_name, index, choice.is_completed)
          end
        end
      end
    end

    @module_history.each do |k, v|
      v[:chosen_by_default_module1] = v[:module1] - v[:chosen_by_parents_module1]
      v[:chosen_by_default_module2] = v[:module2] - v[:chosen_by_parents_module2]
    end

    @module_history
  end

  def add_choice_to_hash(support_module_name, index, chosen_by_parents)
    @module_history[support_module_name] = {
      module1: 0,
      module2: 0,
      chosen_by_parents_module1: 0,
      chosen_by_parents_module2: 0,
      chosen_by_default_module1: 0,
      chosen_by_default_module2: 0
    } unless @module_history.key? support_module_name

    @module_history[support_module_name]["module#{index + 1}".to_sym] += 1
    @module_history[support_module_name]["chosen_by_parents_module#{index + 1}".to_sym] += 1 if chosen_by_parents
  end
end
