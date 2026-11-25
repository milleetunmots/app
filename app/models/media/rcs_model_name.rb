class Media::RcsModelName

  ADDITIONAL_MESSAGE_NUMBER = 4
  # Spot-Hit affiche « ? » à la place des caractères hors du plan de base d'Unicode (emoji).
  NOT_DISPLAYED_CHARACTERS = /[^\u0000-￿]|[️‍]/

  def initialize(text_messages_bundle:, message_index:)
    @bundle = text_messages_bundle
    @message_index = message_index
  end

  def to_s
    "#{label} ##{@bundle.id}".gsub(NOT_DISPLAYED_CHARACTERS, '').squeeze(' ').strip
  end

  private

  def label
    return module_label if module_weeks.any?
    return "Auto #{@bundle.key}#{" M#{@message_index}" if @message_index > 1}" if @bundle.key.present?
    return "Appel 3 #{@bundle.name[/S\d+\z/] || @bundle.name}M#{@message_index}" if Media::TextMessagesBundle.call3_names.include?(@bundle.name)

    [*@bundle.tag_list.map { |tag| "[#{tag}]" }, @bundle.name, "M#{@message_index}"].join(' ')
  end

  def module_label
    modules = module_weeks.map(&:support_module).uniq
    themes = modules.map { |support_module| "#{SupportModule.human_attribute_name("theme.#{support_module.theme}")} N#{support_module.level}" }
    [themes.uniq.join('/'), age_labels(modules), placements.join('/')].join(' ')
  end

  def module_weeks
    @module_weeks ||= SupportModuleWeek.joins(:support_module).merge(SupportModule.with_theme_level_and_age_range)
                                       .where('medium_id = :id OR additional_medium_id = :id', id: @bundle.id)
                                       .includes(support_module: :support_module_weeks).order(:support_module_id, :position).to_a
  end

  def age_labels(modules)
    order = SupportModule::AGE_RANGE_LIST + SupportModule::MODULE_ZERO_AGE_RANGE_LIST
    modules.flat_map(&:age_ranges).compact_blank.uniq.sort_by { |age_range| order.index(age_range) || order.size }
           .map { |age_range| short_age_label(age_range) }.join('/')
  end

  def short_age_label(age_range)
    SupportModule.human_attribute_name("age_range.#{age_range}").sub(' mois et plus', '+').sub(' mois', '').delete(' ')
  end

  def placements
    module_weeks.map { |week| "S#{week.support_module.support_module_weeks.index(week) + 1}M#{message_number(week)}" }.uniq
  end

  def message_number(week)
    week.additional_medium_id == @bundle.id ? ADDITIONAL_MESSAGE_NUMBER + @message_index - 1 : @message_index
  end
end
