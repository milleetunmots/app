ActiveAdmin.register Media::TextMessagesBundle do

  menu parent: 'Médiathèque', label: 'Trios SMS', priority: 2

  decorate_with Media::TextMessagesBundleDecorator

  has_better_csv
  has_paper_trail
  has_tags
  has_tasks
  use_discard

  register_text_messages_bundle_index
  register_text_messages_bundle_show
  register_text_messages_bundle_form

  # ---------------------------------------------------------------------------
  # ACTIONS
  # ---------------------------------------------------------------------------

  action_item :redraft, only: :show do
    link_to 'Remettre en brouillon',
            [:redraft, :admin, resource],
            class: 'drafts-link red'
  end

  member_action :redraft do
    @task = Task.new
    render 'admin/media/text_messages_bundles/redraft'
  end

  member_action :draft, method: :put do
    @task = Task.new
    task_params = params.require(:task).permit(:title, :description, :due_date, :assignee_id)
    if task_params[:title]
      @task.attributes = task_params
      @task.related = resource
      @task.reporter = current_admin_user
    end
    resource.class.transaction do
      if (@task.title.blank? or @task.save) && resource.draft
        redirect_to admin_media_text_messages_bundle_draft_path(resource),
                    notice: 'Remis en brouillon'
      else
        flash[:error] = 'Impossible à remettre en brouillon'
        render 'admin/media/text_messages_bundles/redraft'
      end
    end
  end

end
