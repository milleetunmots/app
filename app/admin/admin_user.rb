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
    f.inputs do
      f.input :name
      f.input :email
      f.input :user_role,
        collection: admin_user_role_select_collection,
        input_html: {data: {select2: {}}}
      f.input :password
      f.input :password_confirmation, required: true
    end
    f.actions
  end

  controller do
    def destroy
      tasks_assigned_count = resource.assigned_tasks.todo.count
      destroy! do |format|
        if resource.destroyed?
          format.html do
            case tasks_assigned_count
            when 0
              redirect_to admin_admin_users_url, alert: "Utilisateur supprimé"
            else
              redirect_to admin_tasks_url(scope: 'todo'), alert: "L'utilisateur supprimé avait #{tasks_assigned_count} tâche assignée(s) et non executée(s)."
            end
          end
        end
      end
    end
  end

  permit_params :name, :email, :user_role, :password, :password_confirmation

end
