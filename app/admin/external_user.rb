ActiveAdmin.register ExternalUser do
  index do
    selectable_column
    id_column
    column :email
    column :role
    column :source
    column :created_at do |decorated|
      l decorated.created_at.to_date, format: :default
    end
    column :updated_at do |decorated|
      l decorated.updated_at.to_date, format: :default
    end
    actions dropdown: true
  end

  permit_params :email, :password, :role, :source_id

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs do
      f.input :email
      if current_admin_user.admin?
        f.input :role,
          collection: ExternalUser::roles.keys,
          input_html: {data: {select2: {}}}
      end
      f.input :source_id,
            as: :select,
            collection: source_select_collection,
            input_html: { data: { select2: {} } }
      f.input :password
    end
    f.actions
  end
end
