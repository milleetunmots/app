class ChildSupport::FillParentsAvailableSupportModulesService

  def initialize(group_id, second_support_module, support_module_sent_date)
    @group = Group.includes(children: :child_support).find(group_id)
    @second_support_module = second_support_module
    @support_module_sent_date = support_module_sent_date
    @children_with_missing_child_support = []
  end

  def call
    @group.children.where(group_status: 'active').each do |child|
      @children_with_missing_child_support << child.id and next unless child.child_support

      next if child.siblings_on_same_group.count > 1 && child.child_support.current_child != child

      parent1_support_module_ids = order_available_support_modules(child, child.parent1)
      parent2_support_module_ids = order_available_support_modules(child, child.parent2)
      if @second_support_module
        filling_child_support(child, parent1_support_module_ids, parent2_support_module_ids)
      else
        filling_child_support(child, parent1_support_module_ids.first(3), parent2_support_module_ids.first(3))
      end
    end
    Rollbar.error(
      "Certains enfants de la cohorte #{@group.id} n'ont pas de fiche de suivi",
      children: @children_with_missing_child_support,
      source: 'ChildSupport::FillParentsAvailableSupportModulesService'
    ) if @children_with_missing_child_support.any?
    self
  end

  private

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
        level = support_modules.where(theme: theme).minimum(:level)
        available_support_modules_group_by_themes[theme] = support_modules.where(theme: theme, level: level).pluck(:id)
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

  def find_available_support_modules(child, parent)
    child_age_range = case child.duration_in_months(child.birthdate, @support_module_sent_date)
                      when 0..4
                        SupportModule::LESS_THAN_FIVE
                      when 5..11
                        SupportModule::FIVE_TO_ELEVEN
                      when 12..17
                        SupportModule::TWELVE_TO_SEVENTEEN
                      when 18..23
                        SupportModule::EIGHTEEN_TO_TWENTY_THREE
                      when 24..29
                        SupportModule::TWENTY_FOUR_TO_TWENTY_NINE
                      when 30..35
                        SupportModule::THIRTY_TO_THIRTY_FIVE
                      # when 36..40
                      #   SupportModule::THIRTY_SIX_TO_FORTY
                      # when 41..44
                      #   SupportModule::FORTY_ONE_TO_FORTY_FOUR
                      else
                        ''
                      end

    already_done_ids = child.children_support_modules.where(parent: parent).pluck(:support_module_id)

    support_modules = SupportModule.where("'#{child_age_range}' = ANY (age_ranges)").where.not(id: already_done_ids).where.not(theme: SupportModule::READING, level: 1)
    support_modules = support_modules.where(for_bilingual: false) unless child.child_support.is_bilingual == '0_yes'
    support_modules
  end

  def filling_child_support(child, parent1_support_module_ids, parent2_support_module_ids)
    child.child_support.parent1_available_support_module_list = parent1_support_module_ids
    child.child_support.parent2_available_support_module_list = parent2_support_module_ids
    child.child_support.save
  end
end
