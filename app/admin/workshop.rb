ActiveAdmin.register Workshop do

  decorate_with WorkshopDecorator

  has_better_csv
  use_discard

  includes :animator

  index do
    selectable_column
    id_column
    column :name
    column :animator
    column :co_animator
    column :workshop_date
    column :workshop_address
  end

  filter :name
  filter :animator
  filter :address
  filter :postal_code
  filter :city_name

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs do
      f.input :name
      f.input :workshop_date, as: :datepicker
      f.input :animator, input_html: {data: {select2: {}}}
      f.input :co_animator, collection: admin_user_select_collection, input_html: {data: {select2: {}}}
      address_input f
      f.input :participants, collection: parent_select_collection, input_html: {data: {select2: {}}}
      f.input :description, input_html: {rows: 1}
      f.input :invitation_message, input_html: {rows: 5}
    end
    f.actions
  end

  permit_params :name, :workshop_date, :animator_id, :co_animator, :address, :postal_code, :city_name, :description, :invitation_message, participant_ids: []

  show do
    tabs do
      tab "Infos" do
        attributes_table do
          row :name
          row :workshop_date
          row :animator
          row :co_animator
          row :workshop_address
          row :description
          row :invitation_message
        end
      end
    end
  end

  # controller do
  #   def create
  #     workshop_attributes = params.require(:workshop).permit(:name, :workshop_date, :animator_id, :co_animator, :address, :postal_code, :city_name, :description, :invitation_message, participant_ids: []).to_h
  #
  #     @workshop = Workshop.new(workshop_attributes)
  #
  #     @workshop.events.each do |participation|
  #       participation.occurred_at = @workshop.workshop_date
  #       participation.subject = @workshop.name
  #       participation.body = @workshop.description
  #     end
  #
  #     if @workshop.save
        # parents_selected = @workshop.parents_selected.map { |item| "parent.#{item}" }
        # parents_tagged = Parent.tagged_with(@workshop.guests_tag).pluck(:id).map { |item| "parent.#{item}" }
        # guest_list = (parents_selected + parents_tagged).uniq
        #
        # guest_list.each do |guest|
        #   parent_id = guest.gsub("parent.", "").to_i
        #   event = Event.new(related_type: "Parent", related_id: parent_id, comments: @workshop.description, type: "Events::WorkshopParticipation", occurred_at: @workshop.occurred_at, workshop_id: @workshop.id)
        #   event.save
        #   response_url = " Pour vous inscrire ou dire que vous ne venez pas, cliquer sur ce lien: #{request.base_url}/w/#{parent_id}/#{@workshop.id}"
        #
        #   ProgramMessageService.new(Date.today, Time.zone.now.strftime("%H:%M"), [guest], @workshop.invitation_message + response_url).call
        # end

  #       redirect_to admin_workshop_path @workshop
  #     end
  #   end
  # end

end
