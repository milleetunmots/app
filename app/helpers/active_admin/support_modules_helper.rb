module ActiveAdmin::SupportModulesHelper
  def support_module_collection(selected_values)
    # puts selected values in order first so they appear in the input in the right order

    support_modules = SupportModule.decorate.map { |sm| [sm.name_with_tags, sm.id.to_s] }

    support_modules.sort_by { |e| selected_values.index(e[1]) || Float::INFINITY }
  end

  def available_support_module_input(form, input_name, options = {})
    input_html = {
      data: {
        select2: {}
      }
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
    SupportModule::THEME_LIST.map do |v|
      [
        SupportModule.human_attribute_name("theme.#{v}"),
        v
      ]
    end
  end

  def support_module_age_range_select_collection
    SupportModule::AGE_RANGE_LIST.map do |v|
      [
        SupportModule.human_attribute_name("age_range.#{v}"),
        v
      ]
    end
  end
end
