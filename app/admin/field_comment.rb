ActiveAdmin.register FieldComment do

  decorate_with FieldCommentDecorator

  actions :all, except: [:new, :create, :edit, :update]

  has_better_csv

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  includes :related, :author

  index do
    selectable_column
    id_column
    column :author, sortable: :author_id
    column :related do |decorated|
      decorated.related_link
    end
    column :field
    column :content
    column :created_at do |decorated|
      decorated.created_at_date
    end
    column :updated_at do |decorated|
      decorated.updated_at_date
    end
    actions dropdown: true
  end

  scope(:mine, default: true, group: :author) { |scope| scope.posted_by(current_admin_user) }
  scope :all, group: :author

  filter :author
  filter :content
  filter :created_at
  filter :updated_at

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :author
      row :related
      row :field
      row :content
      row :created_at
      row :updated_at
    end
  end

end
