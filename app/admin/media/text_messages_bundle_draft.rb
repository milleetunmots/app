ActiveAdmin.register Media::TextMessagesBundleDraft do

  menu parent: 'Médiathèque', label: 'Brouillons', priority: 1

  decorate_with Media::TextMessagesBundleDraftDecorator

  has_better_csv
  has_paper_trail
  has_tags
  has_tasks
  use_discard

  register_text_messages_bundle_index(with_comments: true)
  register_text_messages_bundle_show(with_comments: true)
  register_comments
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

end
