module ActiveAdmin::SupportModulesHelper
  def support_module_collection
    SupportModule.order('LOWER(name)').decorate.map { |sm| [sm.name_with_tags, sm.id] }
  end

  def available_support_module_input(form, input_name, options = {})
    input_html = {
      data: {
        select2: {}
      }
    }

    form.input input_name,
               {
                 multiple: true,
                 collection: support_module_collection,
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
