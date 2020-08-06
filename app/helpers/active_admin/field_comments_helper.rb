module ActiveAdmin::FieldCommentsHelper

  def field_comments_for(field)
    field_comments = FieldComment.relating(resource.model)
                                 .concerning(field)
                                 .order(:created_at)
    render 'active_admin/field_comments/field_comments',
           field: field,
           field_comments: field_comments
  end

  def link_to_comment_field(field)
    link_to(
      {
        action: :quick_field_comment,
        field: field
      },
      target: '_blank',
      class: 'quick-field-comment-btn',
      data: {
        prompt: I18n.t('active_admin.field_comments.quick.prompt'),
        success: I18n.t('active_admin.field_comments.quick.success'),
        error: I18n.t('active_admin.field_comments.quick.error')
      }
    ) do
      content_tag(:span, class: 'fa-stack fa-xs') do
        (
          content_tag(:i, '', class: 'fas fa-comment fa-stack-2x')
        ) + (
          content_tag(:i, '', class: 'fas fa-plus fa-stack-1x')
        )
      end
    end
  end

end
