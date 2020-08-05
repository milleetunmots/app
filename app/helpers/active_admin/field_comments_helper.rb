module ActiveAdmin::FieldCommentsHelper

  def url_for_new_field_comment(model)
    new_admin_field_comment_path(
      field_comment: {
        related_type: model.class,
        related_id: model.id
      }
    )
  end

end
