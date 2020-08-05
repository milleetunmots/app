ActiveAdmin.register Media::TextMessagesBundleDraft do

  menu parent: 'Médiathèque', label: 'Trios SMS : Brouillons'

  decorate_with Media::TextMessagesBundleDraftDecorator

  has_better_csv
  has_paper_trail
  has_tags
  use_discard

  register_text_messages_bundle_index
  register_text_messages_bundle_show
  register_text_messages_bundle_form

  # ---------------------------------------------------------------------------
  # ACTIONS
  # ---------------------------------------------------------------------------

  action_item :undraft, only: :show do
    link_to 'Valider',
            [:undraft, :admin, resource],
            method: :put,
            class: 'drafts-link green'
  end

  member_action :undraft, method: :put do
    if resource.undraft
      redirect_to admin_media_text_messages_bundle_path(resource),
                  notice: 'Sorti des brouillons'
    else
      flash[:error] = 'Impossible à sortir des brouillons'
      redirect_to request.referer
    end
  end

  # ---------------------------------------------------------------------------
  # COMMENTS
  # ---------------------------------------------------------------------------

  sidebar I18n.t('active_admin.field_comments.sidebar.title'),
          partial: 'layouts/active_admin/field_comments/sidebar',
          only: :show

end
