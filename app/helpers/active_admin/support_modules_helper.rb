module ActiveAdmin::SupportModulesHelper

  def support_module_collection
    SupportModule.order("LOWER(name)").decorate.map { |sm| [sm.name_with_tags, sm.id] }
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
end
