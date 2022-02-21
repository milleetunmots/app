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
    column :current_sign_in_at
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

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs do
      f.input :name
      f.input :email
      if current_admin_user.is_admin?
        f.input :user_role,
          collection: admin_user_role_select_collection,
          input_html: {data: {select2: {}}}
      end
      if !params[:id] || current_admin_user.id == params[:id].to_i
        f.input :password
        f.input :password_confirmation, required: true
      end
    end
    f.actions
  end

  controller do
    def destroy
      tasks_assigned_count = resource.assigned_tasks.todo.count
      destroy! do |format|
        redirect_to request.referer, alert: "Suppression impossible." and return unless resource.destroyed?
        format.html do
          redirect_to admin_admin_users_url, alert: "Utilisateur supprimé" and return if tasks_assigned_count.zero?
          redirect_to admin_tasks_url(scope: 'todo'), alert: "L'utilisateur supprimé avait #{tasks_assigned_count} tâche assignée(s) et non executée(s)."
        end
      end
    end
  end

  permit_params do
    parameters = [:name, :email]
    parameters.push :user_role if current_admin_user.is_admin?
    if !params[:id] || current_admin_user == AdminUser.find(params[:id])
      parameters.push :password
      parameters.push :password_confirmation
    end
    parameters
  end

end
