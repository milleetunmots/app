module ActiveAdmin::ParentsHelper

  def parent_gender_select_collection
    Parent::GENDERS.map do |v|
      [
        Parent.human_attribute_name("gender.#{v}"),
        v
      ]
    end
  end

  def parent_select_collection
    Parent.order(:id).map(&:decorate)
  end

  def selected_modules_input(form, options = {}, width: nil)
    input_html = {
      data: {
        select2: {
          tags: true,
          tokenSeparators: [","]
        }
      }
    }
    input_html[:width] = width if width
    form.input :selected_module_list,
               {
                 multiple: true,
                 label: "Modules choisis",
                 collection: tag_name_collection,
                 input_html: input_html
               }.deep_merge(options)
  end
end
