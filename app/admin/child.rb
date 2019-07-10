ActiveAdmin.register Child do

  decorate_with ChildDecorator

  has_paper_trail
  has_tasks

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  includes :parent1, :parent2, :child_support

  index do
    selectable_column
    id_column
    column :gender
    column :first_name
    column :last_name
    column :age, sortable: :birthdate
    column :parent1, sortable: :parent1_id
    column :parent2, sortable: :parent2_id
    column :child_support do |model|
      model.child_support_status
    end
    column :created_at do |model|
      l model.created_at.to_date, format: :default
    end
    column :updated_at do |model|
      l model.updated_at.to_date, format: :default
    end
    actions
  end

  scope :all, default: true

  scope :months_between_0_and_3, group: :months
  scope :months_between_3_and_6, group: :months
  scope :months_between_6_and_12, group: :months
  scope :months_between_12_and_18, group: :months
  scope :months_between_18_and_24, group: :months
  scope :months_more_than_24, group: :months

  scope :with_support, group: :support
  scope :without_support, group: :support

  filter :gender,
         as: :check_boxes,
         collection: proc { child_gender_select_collection }
  filter :first_name
  filter :last_name
  filter :birthdate
  filter :months,
         as: :numeric,
         filters: [:equals, :gteq, :lt]
  filter :created_at
  filter :updated_at

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.inputs do
      f.input :parent1,
              collection: child_parent_select_collection,
              input_html: { data: { select2: {} } }
      f.input :should_contact_parent1
      f.input :parent2,
              collection: child_parent_select_collection,
              input_html: { data: { select2: {} } }
      f.input :should_contact_parent2
      f.input :gender,
              as: :radio,
              collection: child_gender_select_collection
      f.input :first_name
      f.input :last_name
      f.input :birthdate, as: :datepicker
    end
    f.actions
  end

  permit_params :parent1_id, :parent2_id,
                :should_contact_parent1, :should_contact_parent2,
                :gender, :first_name, :last_name, :birthdate

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :parent1
      row :should_contact_parent1
      row :parent2
      row :should_contact_parent2
      row :first_name
      row :last_name
      row :birthdate
      row :age
      row :gender
      row :created_at
      row :updated_at
    end
  end

  action_item :show_support,
              only: :show,
              if: proc { resource.child_support } do
    link_to I18n.t('child.show_support_link'), [:admin, resource.child_support]
  end
  action_item :create_support,
              only: :show,
              if: proc { !resource.child_support } do
    link_to I18n.t('child.create_support_link'), [:create_support, :admin, resource]
  end
  member_action :create_support do
    if already_existing_child_support = resource.child_support
      redirect_to [:admin, already_existing_child_support], notice: I18n.t('child.support_already_existed')
    else
      resource.create_support!
      redirect_to [:edit, :admin, resource.child_support]
    end
  end

end
