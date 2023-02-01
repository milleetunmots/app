ActiveAdmin.register Group do

  decorate_with GroupDecorator

  has_better_csv
  has_paper_trail
  has_tasks
  use_discard

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    selectable_column
    id_column
    column :name
    column :children
    column :started_at
    column :ended_at
    column :support_modules_count
    column :is_programmed
    column :created_at do |model|
      l model.created_at.to_date, format: :default
    end
    column :updated_at do |model|
      l model.updated_at.to_date, format: :default
    end
    actions dropdown: true do |decorated|
      discard_links_args(decorated.model).each do |args|
        item *args
      end
    end
  end

  filter :name
  filter :started_at
  filter :ended_at
  filter :support_modules_count
  filter :is_programmed
  filter :created_at
  filter :updated_at

  scope :all, default: true
  scope :not_ended
  scope :ended

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs do
      f.input :name
      f.input :started_at, as: :datepicker
      f.input :ended_at, as: :datepicker
      f.input :support_modules_count
    end
    f.actions
  end

  permit_params :name, :started_at, :ended_at, :support_modules_count

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :name
      row :children
      row :started_at
      row :ended_at
      row :support_modules_count
      row :is_programmed
    end
  end

  # ---------------------------------------------------------------------------
  # MEMBER ACTIONS
  # ---------------------------------------------------------------------------

  action_item :program,
    only: :show,
    if: proc { !resource.is_programmed } do
    link_to I18n.t("group.program_link"), [:program, :admin, resource]
  end

  member_action :program do
    service = Group::ProgramService.new(resource.object).call

    if service.errors.empty?
      redirect_to [:admin, resource], notice: "Les futurs tâches, envois de sms ont été programmé avec succès."
    else
      flash[:alert] = service.errors
      redirect_to [:admin, resource]
    end
  end

end
