ActiveAdmin.register Source do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :name, :channel, :department, :utm, :comment
  #
  # or
  #
  # permit_params do
  #   permitted = [:name, :channel, :department, :utm, :comment]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  decorate_with SourceDecorator

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    selectable_column
    id_column
    column :name
    column :channel
    column :department
    column :comment
    actions
  end

  filter :name
  filter :channel
  filter :department
  filter :created_at
  filter :updated_at

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs do
      f.input :name
      f.input :channel, collection: Source::CHANNEL_LIST
      f.input :department
      f.input :comment
    end
    f.actions
  end

  permit_params :name, :channel, :department, :comment

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :name
      row :channel
      row :department
      row :comment
      row :created_at
      row :updated_at
    end
  end
end
