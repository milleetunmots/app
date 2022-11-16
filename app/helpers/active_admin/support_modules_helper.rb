module ActiveAdmin::SupportModulesHelper

  def support_module_collection
    SupportModule.order("LOWER(name)").pluck(:name, :id)
  end

  def available_support_module_input(form, options = {})
    input_html = {
      data: {
        select2: {}
      }
    }

    form.input :available_support_module_list,
               {
                 multiple: true,
                 collection: support_module_collection,
                 input_html: input_html
               }.deep_merge(options)
  end
end
