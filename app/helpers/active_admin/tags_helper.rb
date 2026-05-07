module ActiveAdmin::TagsHelper

  def tag_name_collection(current_admin_user_is_caller_or_animator = false)
    if current_admin_user_is_caller_or_animator
      ActsAsTaggableOn::Tag.where(is_visible_by_callers_and_animators: current_admin_user_is_caller_or_animator).order('LOWER(name)').pluck(:name)
    else
      ActsAsTaggableOn::Tag.order('LOWER(name)').pluck(:name)
    end
  end

  def module_name_collection
    ActsAsTaggableOn::Tag.order('LOWER(name)').for_context(:selected_modules).pluck(:name)
  end

  def tags_input(form, current_admin_user_is_caller_or_animator, context_list = 'tag_list', options = {})
    input_html = {
      data: {
        select2: {
          tags: true,
          tokenSeparators: [',']
        }
      }
    }

    form.input context_list.to_sym, {
      multiple: true,
      label: 'Tags',
      collection: tag_name_collection(current_admin_user_is_caller_or_animator),
      input_html: input_html
    }.deep_merge(options)
  end
end
