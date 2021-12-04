ActiveAdmin.register Workshop do

  decorate_with WorkshopDecorator

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
  filter :parents_selected, as: :select,
                            collection: proc { parent_select_collection },
                            input_html: {multiple: true, data: {select2: {}}},
                            label: "Parents"

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs do
      f.input :title
      f.input :occurred_at
      f.input :animator, input_html: {data: {select2: {}}}
      f.input :co_animator, collection: admin_user_select_collection, input_html: {data: {select2: {}}}
      address_input f
      f.input :description, input_html: {rows: 1}
      f.input :invitation_message, input_html: {rows: 5}
      f.input :parents_selected, multiple: true, collection: parent_select_collection, input_html: {data: {select2: {}}}
      f.input :guests_tag, collection: tag_name_collection, input_html: {data: {select2: {}}}
    end
    f.actions
  end

  permit_params :title, :occurred_at, :animator_id, :co_animator, :address, :postal_code, :city_name, :description, :guests_tag, :invitation_message, parents_selected: []

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
          row :invitation_message
          row :guests_tag
          row :workshop_parents_list
        end
      end
    end
  end

  controller do
    def create
      workshop_attributes = params.require(:workshop).permit(:title, :occurred_at, :animator_id, :co_animator, :address, :postal_code, :city_name, :description, :guests_tag, :invitation_message, parents_selected: []).to_h
      workshop_attributes["parents_selected"] = workshop_attributes["parents_selected"].map(&:to_i).delete_if { |i| i == 0 }

      @workshop = Workshop.new(workshop_attributes)

      if @workshop.save
        parents_selected = @workshop.parents_selected.map { |item| "parent.#{item}" }
        parents_tagged = Parent.tagged_with(@workshop.guests_tag).pluck(:id).map { |item| "parent.#{item}" }
        guest_list = (parents_selected + parents_tagged).uniq

        guest_list.each do |guest|
          parent_id = guest.gsub("parent.", "").to_i
          event = Event.new(
            related_type: "Parent",
            related_id: parent_id,
            comments: @workshop.description,
            type: "Events::WorkshopParticipation",
            occurred_at: @workshop.occurred_at,
            workshop_id: @workshop.id
          )
          event.save
          response_url = " Cliquez sur ce lien pour repondre à l'invitation: #{request.base_url}/w/#{parent_id}/#{@workshop.id}"

          ProgramMessageService.new(
            Date.today,
            Time.zone.now.strftime("%H:%M"),
            [guest],
            @workshop.invitation_message + response_url
          ).call
        end

        redirect_to admin_workshop_path @workshop
      end
    end
  end

end
