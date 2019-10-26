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
    column :postal_code
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

  scope :months_between_0_and_12, group: :months
  scope :months_between_12_and_24, group: :months
  scope :months_between_24_and_36, group: :months
  scope :months_more_than_36, group: :months

  scope :with_support, group: :support
  scope :without_support, group: :support

  filter :gender,
         as: :check_boxes,
         collection: proc { child_gender_select_collection }
  filter :first_name
  filter :last_name
  filter :postal_code,
         as: :string
  filter :birthdate
  filter :months,
         as: :numeric,
         filters: [:equals, :gteq, :lt]
  filter :created_at
  filter :updated_at

  batch_action :create_support, form: -> {
    {
      I18n.t('activerecord.attributes.child_support.supporter') => AdminUser.pluck(:name, :id)
    }
  } do |ids, inputs|
    batch_action_collection.find(ids).each do |child|
      next if already_existing_child_support = child.child_support
      supporter_id = inputs[I18n.t('activerecord.attributes.child_support.supporter')]
      child.create_support!(supporter_id: supporter_id)
    end
    redirect_to collection_path, notice: I18n.t('child.supports_created')
  end

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
      row :registered_by
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
      resource.create_support!(supporter: current_admin_user)
      redirect_to [:edit, :admin, resource.child_support]
    end
  end



  # ---------------------------------------------------------------------------
  # IMPORT
  # ---------------------------------------------------------------------------

  action_item :new_import,
              only: :index do
    link_to I18n.t('child.new_import_link'), [:new_import, :admin, :children]
  end
  collection_action :new_import do
    @import_action = perform_import_admin_children_path
  end
  collection_action :perform_import, method: :post do
    @csv_file = params[:import][:csv_file]

    service = ChildrenImportService.new(csv_file: @csv_file, current_admin_user: current_admin_user).call

    if service.errors.empty?
      redirect_to admin_children_path, notice: 'Import terminé'
    else
      @import_action = perform_import_admin_children_path
      @errors = service.errors
      render :new_import
    end
  end

  # ---------------------------------------------------------------------------
  # CSV EXPORT
  # ---------------------------------------------------------------------------

  #
  csv do
    column :id
    column :first_name
    column :last_name
    column :birthdate
    column :age
    column(:gender) { |child| child.gender_text }
    column :address
    column :city_name
    column :postal_code
    column(:parent1_gender) { |child| Parent.human_attribute_name("gender.#{child.parent1_gender}") }
    column(:parent1_first_name) { |child| child.parent1_first_name }
    column(:parent1_last_name) { |child| child.parent1_last_name }
    column(:parent1_phone_number_national) { |child| child.parent1_phone_number_national }
    column :should_contact_parent1
    column(:parent2_gender) { |child| child.parent2_gender && Parent.human_attribute_name("gender.#{child.parent2_gender}") }
    column(:parent2_first_name) { |child| child.parent2_first_name }
    column(:parent2_last_name) { |child| child.parent2_last_name }
    column(:parent2_phone_number_national) { |child| child.parent2_phone_number_national }
    column :should_contact_parent2
    column :registered_by
    column :created_at
    column :updated_at
  end

end
