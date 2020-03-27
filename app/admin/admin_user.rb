ActiveAdmin.register AdminUser do

  decorate_with AdminUserDecorator

  has_better_csv

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    selectable_column
    id_column
    column :name
    column :email do |decorated|
      decorated.email_link
    end
    column :current_sign_in_at
    column :sign_in_count
    column :created_at do |decorated|
      l decorated.created_at.to_date, format: :default
    end
    column :updated_at do |decorated|
      l decorated.updated_at.to_date, format: :default
    end
    actions
  end

  filter :email
  filter :current_sign_in_at
  filter :sign_in_count
  filter :created_at

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.inputs do
      f.input :name
      f.input :email
      f.input :password
      f.input :password_confirmation, required: true
    end
    f.actions
  end

  permit_params :name, :email, :password, :password_confirmation

end
