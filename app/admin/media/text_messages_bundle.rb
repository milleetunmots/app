ActiveAdmin.register Media::TextMessagesBundle do

  menu parent: 'Médiathèque', label: 'Trios SMS'

  decorate_with Media::TextMessagesBundleDecorator

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

  action_item :draft, only: :show do
    link_to 'Remettre en brouillon',
            [:draft, :admin, resource],
            method: :put,
            class: 'drafts-link red'
  end

  member_action :draft, method: :put do
    if resource.draft
      redirect_to admin_media_text_messages_bundle_draft_path(resource),
                  notice: 'Remis en brouillon'
    else
      flash[:error] = 'Impossible à remettre en brouillon'
      redirect_to request.referer
    end
  end

end
