module ActiveAdmin::TagsHelper

  def tag_name_collection
    ActsAsTaggableOn::Tag.order("LOWER(name)").pluck(:name)
  end

  def module_name_collection
    ActsAsTaggableOn::Tag.order("LOWER(name)").for_context(:selected_modules).pluck(:name)
  end

  def tags_input(form, context_list = 'tag_list', options = {})
    input_html = {
      data: {
        select2: {
          tags: true,
          tokenSeparators: [","]
        }
      }
    }

    form.input context_list.to_sym, {
        multiple: true,
        label: "Tags",
        collection: tag_name_collection,
        input_html: input_html
      }.deep_merge(options)
  end
end
