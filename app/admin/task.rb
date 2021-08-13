ActiveAdmin.register Task do

  decorate_with TaskDecorator

  has_better_csv
  use_discard

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  includes :related, :assignee, :reporter

  index do
    selectable_column
    id_column
    column :title do |model|
      model.title_with_done_icon
    end
    column :due_date
    column :related, sortable: :related
    column :assignee, sortable: :assignee_id
    column :reporter, sortable: :reporter_id
    column :created_at do |model|
      l model.created_at.to_date, format: :default
    end
    actions dropdown: true do |decorated|
      discard_links_args(decorated.model).each do |args|
        item *args
      end
    end
  end

  config.sort_order = 'default_asc'
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

  scope(:mine, default: true, group: :assignee) { |scope| scope.assigned_to(current_admin_user) }
  scope :all, group: :assignee
  scope :todo

  # scope :done
  # scope :all

  filter :title
  filter :assignee,
         input_html: { data: { select2: {} } }
  filter :reporter,
         input_html: { data: { select2: {} } }
  filter :description
  filter :due_date
  filter :created_at
  filter :updated_at

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.semantic_errors
    f.inputs do
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

      f.input :title
      f.input :description, input_html: { rows: 10 }
      f.input :due_date, as: :datepicker
      f.input :is_done, as: :boolean
      f.input :reporter,
              input_html: { data: { select2: {} } }
      f.input :assignee,
              input_html: { data: { select2: {} } }
    end
    f.actions
  end

  permit_params :reporter_id, :assignee_id, :related_type, :related_id,
                :title, :description, :due_date, :done_at, :is_done

  controller do
    def build_new_resource
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
      row :related
      row :title
      row :description
      row :due_date
      row :done_at
      row :created_at
      row :updated_at
    end
  end

end
