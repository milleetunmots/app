class ChildrenSupportModule

  class FillParentsAvailableSupportModulesJob < ApplicationJob

    def perform(group_id, second_support_module)
      group = Group.includes(children: :child_support).find(group_id)

      group.children.each do |child|
        parent1_support_module_ids = order_available_support_modules(child, child.parent1)
        parent2_support_module_ids = order_available_support_modules(child, child.parent2)
        if second_support_module
          filling_child_support(child, parent1_support_module_ids, parent2_support_module_ids)
        else
          filling_child_support(child, parent1_support_module_ids.first(3), parent2_support_module_ids.first(3))
        end
      end
    end

    private

    def find_available_support_modules(child, parent)
      child_age_range = case child.months
                        when 0..5
                          SupportModule::LESS_THAN_SIX
                        when 6..11
                          SupportModule::SIX_TO_ELEVEN
                        when 12..17
                          SupportModule::TWELVE_TO_SEVENTEEN
                        when 18..23
                          SupportModule::EIGHTEEN_TO_TWENTY_THREE
                        else
                          ''
                        end

      already_done_ids = child.children_support_modules.where(parent: parent).pluck(:support_module_id)

      support_modules = SupportModule.where("'#{child_age_range}' = ANY (age_ranges)").where.not(id: already_done_ids)
      support_modules = support_modules.where(for_bilingual: false) unless child.child_support.is_bilingual
      support_modules
    end

    def order_available_support_modules(child, parent)
      support_modules = find_available_support_modules(child, parent)
      available_support_modules_group_by_themes = {}
      available_support_modules_group_by_themes_already_done = {}
      available_support_modules_ordered = []

      already_done_themes_and_levels = SupportModule.joins(:children_support_modules).where(children_support_modules: { parent: parent, child: child }).order(for_bilingual: :desc).pluck(:theme, :level).uniq

      SupportModule::THEME_LIST.each do |theme|
        if theme.in?(already_done_themes_and_levels.map(&:first))
          level = already_done_themes_and_levels.select { |item| item.first == theme }.map(&:second).max + 1
          available_support_modules_group_by_themes_already_done[theme] = support_modules.where(theme: theme, level: level).pluck(:id)
        else
          available_support_modules_group_by_themes[theme] = support_modules.where(theme: theme, level: 1).pluck(:id)
        end
      end

      until available_support_modules_group_by_themes.empty?
        available_support_modules_group_by_themes.reject! { |_theme, support_modules_array| support_modules_array.blank? }
        available_support_modules_group_by_themes.each do |_theme, support_modules_array|
          available_support_modules_ordered << support_modules_array.shift
        end
      end

      until available_support_modules_group_by_themes_already_done.empty?
        available_support_modules_group_by_themes_already_done.reject! { |_theme, support_modules_array| support_modules_array.blank? }
        available_support_modules_group_by_themes_already_done.each do |_theme, support_modules_array|
          available_support_modules_ordered << support_modules_array.shift
        end
      end

      available_support_modules_ordered
    end

    def filling_child_support(child, parent1_support_module_ids, parent2_support_module_ids)
      child.child_support.parent1_available_support_module_list = parent1_support_module_ids
      child.child_support.parent2_available_support_module_list = parent2_support_module_ids
      child.child_support.save
    end
  end
end
