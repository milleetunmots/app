ActiveAdmin.register Workshop do

  #   decorate_with WorkshopDecorator

  has_better_csv
  use_discard

  includes :animator

  index do
    selectable_column
    id_column
    column :title
    column :animator
    column :co_animator
    column :workshop_address
    column :guests_tag
  end

  filter :title
  filter :animator
  filter :address
  filter :postal_code
  filter :city_name
  filter :guests_tag
  #
  #   form do |f|
  #     f.semantic_errors *f.object.errors.keys
  #     f.inputs do
  #       f.input :title
  #       f.input :occurred_at
  #       f.input :animator, input_html: {data: {select2: {}}}
  #       f.input :co_animator, collection: workshop_co_animator_select_collection, input_html: {data: {select2: {}}}
  #       address_input f
  #       f.input :description, input_html: {rows: 3}
  #       f.input :parents_selected, multiple: true, collection: parent_collection, input_html: {data: {select2: {}}}
  #       f.input :guests_tag, collection: workshop_tag_collection, input_html: {data: {select2: {}}}
  #     end
  #     f.actions
  #   end
  #
  #   permit_params :title, :occurred_at, :animator_id, :co_animator, :address, :postal_code, :city_name, :description, :guests_tag, parents_selected: []

  show do
    tabs do
      tab "Infos" do
        attributes_table do
          row :title
          row :occurred_at
          row :animator
          row :co_animator
          row :workshop_address
          row :description
          row :guests_tag
        end
      end
    end
  end

  #   controller do
  #     def create
  #       workshop_attributes = params.require(:workshop).permit(:title, :occurred_at, :animator_id, :co_animator, :address, :postal_code, :city_name, :description, :guests_tag, parents_selected: []).to_h
  #
  #       @workshop = Workshop.new(workshop_attributes)
  #       @workshop.save
  #
  #       parents_selected = Parent.find(workshop_attributes["parents_selected"].map(&:to_i).delete_if { |i| i == 0 })
  #       parents_tagged = Parent.tagged_with(workshop_attributes[:guests_tag]).to_a
  #
  #       guest_list = (parents_selected + parents_tagged).uniq
  #
  #       guest_list.each do |guest|
  #         event = Event.new(
  #           related: guest,
  #           comments: @workshop.description,
  #           type: "Events::WorkshopParticipation",
  #           occurred_at: @workshop.occurred_at,
  #           workshop_id: @workshop.id
  #         )
  #         event.save
  #       end
  #       redirect_to admin_workshop_path @workshop
  #     end
  #   end
  #
end
