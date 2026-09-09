module ActiveAdmin::SupportModulesHelper
  # Les modules réellement proposés au parent sont les premiers de la liste :
  # FillParentsAvailableSupportModulesService n'en retient que 3
  RECOMMENDED_SUPPORT_MODULE_COUNT = 3

  # Décore les modules dans l'ordre de la colonne tableau, en une seule requête
  def decorated_support_modules(support_module_ids)
    ids = Array(support_module_ids).compact_blank
    by_id = SupportModule.where(id: ids).index_by { |support_module| support_module.id.to_s }
    ids.filter_map { |id| by_id[id.to_s]&.decorate }
  end

  # Lien vers le contenu du module sur Airtable, ouvert dans un nouvel onglet.
  # Accessible à tous les rôles : c'est une simple URL externe.
  def support_module_airtable_link(support_module, label: nil)
    return if support_module.nil?

    decorated = support_module.decorated? ? support_module : support_module.decorate
    url = decorated.airtable_folder_url
    return if url.blank?

    link_to url, target: '_blank', rel: 'noopener',
                 class: 'support-module-airtable-link',
                 title: 'Ouvrir le contenu du module sur Airtable' do
      safe_join([
                  label || decorated.name_without_emoji,
                  tag.i(class: 'fas fa-external-link-alt')
                ], ' ')
    end
  end

  def support_module_collection(selected_values = [])
    # puts selected values in order first so they appear in the input in the right order

    support_modules = SupportModule.decorate.map { |sm| [sm.name_with_tags, sm.id.to_s] }

    support_modules&.sort_by { |e| selected_values&.index(e[1]) || Float::INFINITY }
  end

  def available_support_module_input(form, input_name, disabled, options = {})
    input_html = {
      data: {
        select2: {}
      },
      disabled: disabled
    }

    selected_values = form.object.send(input_name)

    form.input input_name,
               {
                 multiple: true,
                 collection: support_module_collection(selected_values),
                 input_html: input_html
               }.deep_merge(options)
  end

  def support_module_theme_select_collection
    SupportModule::THEME_LIST_INCLUDING_MODULE_ZERO.map do |v|
      [
        SupportModule.human_attribute_name("theme.#{v}"),
        v
      ]
    end
  end

  def support_module_age_range_select_collection(theme)
    age_range_list = SupportModule::MODULE_ZERO_THEME_LIST.include?(theme) ? SupportModule::MODULE_ZERO_AGE_RANGE_LIST : SupportModule::AGE_RANGE_LIST
    age_range_list.map do |v|
      [
        SupportModule.human_attribute_name("age_range.#{v}"),
        v
      ]
    end
  end
end
