module ActiveAdmin::WorkshopsHelper
  def workshop_topic_select_collection
    Workshop::TOPICS.map do |v|
      [Workshop.human_attribute_name("topic.#{v}"), v]
    end
  end

  def lands_input(form, options = {}, width: nil)
    input_html = {
      data: {
        select2: {
          tags: true,
          tokenSeparators: [","]
        }
      }
    }
    input_html[:width] = width if width
    form.input :land_list,
               {
                 multiple: true,
                 label: "Terrain",
                 collection: lands_collection,
                 input_html: input_html
               }.deep_merge(options)
  end

  def lands_collection
    ActsAsTaggableOn::Tag.where(id: ActsAsTaggableOn::Tagging.where(context: "lands").pluck(:tag_id)).pluck(:name)
  end
end
