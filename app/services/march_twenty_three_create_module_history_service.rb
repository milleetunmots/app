class MarchTwentyThreeCreateModuleHistoryService

  attr_reader :module_history

  def initialize
    @group = Group.find(53)
    @module_history = {}
  end

  def call
    @group.children.each do |child|
      child.children_support_modules.order(:choice_date).each_with_index do |csm, index|
        next if csm.support_module.blank?

        support_module_name = csm.support_module.decorate.name_with_tags.parameterize.to_sym

        @module_history[support_module_name] = { module1: 0, module2: 0 } unless @module_history.key? support_module_name

        @module_history[support_module_name]["module#{index + 1}".to_sym] += 1
      end
    end


    @module_history
  end
end
