ActiveAdmin.register Workshop do

  has_better_csv
  use_discard

  includes :animator, :parents

  index do
    selectable_column
    id_column
    column :title
    column :animator
    column :co_animator
    column :address
    column :postal_code
    column :city_name
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs do
      f.input :title
      f.input :occurred_at
      f.input :animator, input_html: {data: {select2: {}}}
      f.input :co_animator, collection: workshop_co_animator_select_collection, input_html: {data: {select2: {}}}
      address_input f
      f.input :description, input_html: {rows: 3}
      # f.input :parents, collection: parent_collection, input_html: {data: {select2: {}}}
      f.input :guests_tag, collection: Tag.order(:name).pluck(:name), input_html: {data: {select2: {}}}
    end
    f.actions
  end

  permit_params :title, :occurred_at, :animator_id, :co_animator, :address, :postal_code, :city_name, :description, :guests_tag
  # , parent_ids: []

  # show do
  #
  # end

  # controller do
  #   def create
  #     # @workshop = Workshop.create(params[])
  #
  #     byebug
  #   end
  # end

end
