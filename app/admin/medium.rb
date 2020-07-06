ActiveAdmin.register Medium do

  menu label: 'Média', parent: 'Médiathèque'

  actions :index

  decorate_with MediumDecorator

  has_better_csv
  use_discard

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    selectable_column
    id_column
    column :name
    column :type do |decorated|
      decorated.type_name
    end
    column :tags
    column :created_at do |decorated|
      decorated.created_at_date
    end
    column :updated_at do |decorated|
      decorated.updated_at_date
    end
    actions do |decorated|
      discard_links(decorated.model, class: 'member_link')
    end
  end

  filter :name

  filter :occurred_at
  filter :created_at

  action_item :new,
              only: :index do
    dropdown_menu 'Créer' do
      Medium.descendants.each do |klass|
        item klass.model_name.human,
             [:new, :admin, klass.model_name.singular_route_key]
      end
    end
  end

  # # ---------------------------------------------------------------------------
  # # SHOW
  # # ---------------------------------------------------------------------------

  # show do
  #   attributes_table do
  #     row :related do |decorated|
  #       decorated.related_link
  #     end
  #     row :related_first_child do |decorated|
  #       decorated.related_first_child_link
  #     end
  #     row :occurred_at
  #     row :body, class: 'row-pre'
  #     row :created_at
  #     row :discarded_at
  #   end
  # end

  # # ---------------------------------------------------------------------------
  # # FORM
  # # ---------------------------------------------------------------------------

  # controller do
  #   def build_new_resource
  #     resource = super
  #     resource.occurred_at = Time.now
  #     resource
  #   end
  # end

  # form do |f|
  #   f.semantic_errors
  #   f.inputs do
  #     if f.object.related
  #       li class: :input do
  #         label f.object.class.human_attribute_name('related'), class: :label
  #         div style: "padding-top: 6px" do
  #           f.object.decorate.related_link
  #         end
  #       end
  #     end

  #     f.input :related_type, as: :hidden
  #     f.input :related_id, as: :hidden

  #     f.input :occurred_at

  #     f.input :body, as: :text, input_html: { rows: 10 }
  #   end
  #   f.actions
  # end

  # permit_params :related_type, :related_id, :occurred_at, :body

  # # ---------------------------------------------------------------------------
  # # CSV EXPORT
  # # ---------------------------------------------------------------------------

  # csv do
  #   column :id

  #   column :related_id
  #   column :related_name

  #   column :related_first_child_id
  #   column :related_first_child_name

  #   column :related_first_child_group_name
  #   column :related_first_child_has_quit_group

  #   column :occurred_at
  #   column :body

  #   column :created_at
  #   column :updated_at
  #   column :discarded_at
  # end

end
