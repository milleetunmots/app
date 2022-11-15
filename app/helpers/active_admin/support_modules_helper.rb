module ActiveAdmin::SupportModulesHelper

  def support_module_collection
    SupportModule.order("LOWER(name)").pluck(:name)
  end

  def available_support_module_input(form, which_parent, options = {})
    input_html = {
      data: {
        select2: {
          tags: true,
          tokenSeparators: [","]
        }
      }
    }

    form.input which_parent == 'parent1' ? :parent1_available_module : :parent2_available_module,
               {
                 multiple: true,
                 collection: support_module_collection,
                 input_html: input_html
               }.deep_merge(options)
  end
end
