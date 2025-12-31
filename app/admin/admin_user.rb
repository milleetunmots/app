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
    column :user_role
    column :aircall_phone_number
    column :sign_in_count
    column :created_at do |decorated|
      l decorated.created_at.to_date, format: :default
    end
    column :updated_at do |decorated|
      l decorated.updated_at.to_date, format: :default
    end
    actions dropdown: true
  end

  filter :email
  filter :current_sign_in_at
  filter :sign_in_count
  filter :created_at

  scope :account_not_disabled, default: true
  scope :account_disabled

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.semantic_errors *f.object.errors.details.keys
    f.inputs do
      f.input :name
      f.input :email
      if current_admin_user.admin?
        f.input :user_role,
          collection: admin_user_role_select_collection,
          input_html: {data: {select2: {}}}
        f.input :can_export_data
      end
      if !params[:id] || current_admin_user == admin_user_in_params
        f.input :password
        f.input :password_confirmation, required: true
      end
      f.input :can_treat_task, as: :boolean
      f.input :can_send_automatic_sms, as: :boolean
    end
    f.actions
  end

  controller do
    def destroy
      redirect_to request.referer, alert: "Suppression impossible : préférez la désactivation du compte." and return
    end
  end

  permit_params do
    parameters = %i[name email can_treat_task can_send_automatic_sms]
    if current_admin_user.admin?
      parameters.push :user_role
      parameters.push :can_export_data
    end
    if !params[:id] || current_admin_user == AdminUser.find(params[:id])
      parameters.push :password
      parameters.push :password_confirmation
    end
    parameters
  end

  action_item :disable, only: :show do
    unless resource.is_disabled? || current_admin_user.eql?(resource) || !authorized?(:disable, resource)
      link_to('Désactiver le compte', disable_admin_admin_user_path(resource), method: :put)
    end
  end

  action_item :activate, only: :show do
    if resource.is_disabled? && !current_admin_user.eql?(resource) && authorized?(:activate, resource)
      link_to('Réactiver le compte', activate_admin_admin_user_path(resource), method: :put)
    end
  end

  member_action :disable, method: :put do
    authorize!(:disable, resource)
    admin_user = AdminUser.find(params[:id])
    admin_user.update_column(:is_disabled, true)
    flash['notice'] = "L'utilisateur a été désactivé."
    redirect_to admin_admin_user_path(admin_user)
  end

  member_action :activate, method: :put do
    authorize!(:activate, resource)
    admin_user = AdminUser.find(params[:id])
    admin_user.update_column(:is_disabled, false)
    flash['notice'] = "L'utilisateur a été réactivé."
    redirect_to admin_admin_user_path(admin_user)
  end
end
