ActiveAdmin.register Media::TextMessagesBundle do

  menu parent: 'Médiathèque', label: 'Trios SMS', priority: 3

  decorate_with Media::TextMessagesBundleDecorator

  has_better_csv
  has_paper_trail
  has_tags
  # has_tasks
  use_discard

  register_text_messages_bundle_index
  register_text_messages_bundle_show
  register_text_messages_bundle_form

  scope :all, default: true
  scope :single_message

  # ---------------------------------------------------------------------------
  # ACTIONS
  # ---------------------------------------------------------------------------

  action_item :redraft, only: :show do
    link_to 'Remettre en brouillon',
            [:redraft, :admin, resource],
            class: 'drafts-link red'
  end

  action_item :duplicate, only: :show do
    link_to 'Dupliquer', [:duplicate, :admin, resource], class: 'green'
  end

  member_action :duplicate do
    new_resource = resource.duplicate
    new_resource.save!
    redirect_to [:admin, new_resource]
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

  csv do
    column :id
    column :name

    column :body1
    column :file1 do |decorated|
      decorated.image1.name if decorated.image1
    end
    column :link1 do |decorated|
      decorated.link1.url if decorated.link1
    end
    column :body2
    column :file2 do |decorated|
      decorated.image2.name if decorated.image2
    end
    column :link2 do |decorated|
      decorated.link2.url if decorated.link2
    end
    column :body3
    column :file3 do |decorated|
      decorated.image3.name if decorated.image3
    end
    column :link3 do |decorated|
      decorated.link3.url if decorated.link3
    end
    column :tag_list do |decorated|
      decorated.tags
    end
    column :created_at
    column :updated_at
    column :discarded_at
  end

end
