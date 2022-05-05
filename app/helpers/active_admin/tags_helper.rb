module ActiveAdmin::TagsHelper

  def tag_name_collection
    ActsAsTaggableOn::Tag.order("LOWER(name)").pluck(:name)
  end

  def tags_input(form, options = {})
    form.input :tag_list,
      {
        multiple: true,
        label: "Tags",
        collection: tag_name_collection,
        input_html: {
          data: {
            select2: {
              tags: true,
              tokenSeparators: [","]
            }
          }
        }
      }.deep_merge(options)
  end

  def family_tags_input(form, options = {})
    form.input :family_tag_list,
               {
                 multiple: true,
                 label: "Tags de la famille",
                 collection: tag_name_collection,
                 input_html: {
                   data: {
                     select2: {
                       tags: true,
                       tokenSeparators: [","]
                     }
                   }
                 }
               }.deep_merge(options)
  end
end
