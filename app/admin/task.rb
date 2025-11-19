ActiveAdmin.register Task do

  decorate_with TaskDecorator

  config.clear_action_items!

  has_better_csv
  use_discard

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  includes :related, :assignee, :reporter, :treated_by

  index do
    selectable_column
    id_column
    column :title do |model|
      link_to model.title_with_done_icon, admin_task_path(model)
    end
    column :due_date
    column :related, sortable: :related
    column :assignee, sortable: :assignee_id
    column :reporter, sortable: :reporter_id
    column :treated_by
    column :created_at do |model|
      l model.created_at.to_date, format: :default
    end
    actions dropdown: true do |decorated|
      discard_links_args(decorated.model).each do |args|
        item *args
      end
    end
  end

  # config.sort_order = 'default_asc'
  order_by(:default) do |order_clause|
    if order_clause.order == 'desc'
      'done_at ASC, due_date DESC'
    else
      'done_at DESC, due_date'
    end
  end
  order_by(:related) do |order_clause|
    if order_clause.order == 'desc'
      'related_type DESC, related_id DESC'
    else
      'related_type, related_id'
    end
  end

  scope(:caller_task, default: proc { current_admin_user.caller? || current_admin_user.animator? }, group: :reported) { |scope| scope.caller_task(current_admin_user) }
  scope(:mine, default: proc { !current_admin_user.caller? && !current_admin_user.animator? }, group: :assignee, if: proc { !current_admin_user.caller? && !current_admin_user.animator? }) do |scope|
    scope.todo.assigned_to(current_admin_user)
  end
  scope :all, group: :assignee, if: proc { !current_admin_user.caller? && !current_admin_user.animator? }
  scope :todo
  scope :done

  filter :title
  filter :assignee,
         input_html: { data: { select2: {} } }
  filter :reporter,
         input_html: { data: { select2: {} } }
  filter :treated_by, input_html: { data: { select2: {} } }
  filter :description
  filter :due_date
  filter :done_at
  filter :created_at
  filter :updated_at

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :treated_by_id, as: :hidden
      if related = f.object.related&.decorate
        li class: :input do
          label I18n.t('activerecord.attributes.task.related'), class: :label
          div style: "padding-top: 6px" do
            if related.respond_to?(:admin_link)
              related.admin_link
            else
              auto_link related
            end
          end
        end
      end

      f.input :related_type, as: :hidden
      f.input :related_id, as: :hidden

      if f.object.new_related_to_child_support?
        f.input :title, collection: task_title_collection, input_html: { data: { select2: {} } }
        small style:'margin-left:25%; margin-bottom:20px' do
          'Pour plus d’infos sur cette tâche : '.html_safe +
          link_to(
            'cliquez ici',
            'https://www.notion.so/Intitul-s-et-descriptions-des-t-ches-12ef8cee65b580e0a7c2c5ac651c2d5e',
            target: '_blank')
        end
      else
        f.input :title
      end

      f.input :description, input_html: { rows: 10 }
      div style: "#{"display: none;" if f.object.new_related_to_child_support?}" do
        f.input :due_date, as: :datepicker
        f.input :status, collection: task_status_collection, input_html: { data: { select2: {} } }
        f.input :reporter, input_html: { data: { select2: {} } }
        f.input :assignee, input_html: { data: { select2: {} } }
      end
    end
    f.actions
  end

  permit_params :reporter_id, :assignee_id, :related_type, :related_id,
                :title, :description, :due_date, :done_at, :status, :treated_by_id

  controller do
    def build_new_resource
      if params["task"] && params["task"]["related_type"] && params["task"]["related_type"] == "ChildSupport"
        flash.now[:alert] = "Pour un livre non reçu, merci de ne pas attribuer de tâche, cocher la/les case(s) correspondante(s) dans le Suivi"
      end

      resource = super
      resource.reporter = current_admin_user
      resource
    end
  end

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :reporter
      row :assignee
      row :treated_by
      row :related
      row :title
      row :display_description
      row :due_date
      row :done_at
      row :created_at
      row :updated_at
    end
  end
end
