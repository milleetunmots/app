ActiveAdmin.register Workshop do

  decorate_with WorkshopDecorator

  has_better_csv
  has_tags
  use_discard

  includes :animator, :participants

  index do
    selectable_column
    id_column
    column :name
    column :topic
    column :animator
    column :co_animator
    column :workshop_date
    column :workshop_address
    actions dropdown: true do |decorated|
      discard_links_args(decorated.model).each do |args|
        item *args
      end
    end
  end

  filter :name
  filter :animator
  filter :address
  filter :postal_code
  filter :city_name

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs do
      f.input :topic, collection: workshop_topic_select_collection, input_html: {data: {select2: {}}}
      f.input :workshop_date, as: :datepicker
      f.input :animator, input_html: {data: {select2: {}}}
      f.input :co_animator
      address_input f
      f.input :participants, collection: parent_select_collection, input_html: {data: {select2: {}}}
      tags_input(f)
      f.input :invitation_message, input_html: {rows: 5}
    end
    f.actions
  end

  permit_params :topic, :workshop_date, :animator_id, :co_animator, :address, :postal_code, :city_name, :invitation_message, tags_params, participant_ids: []

  show do
    tabs do
      tab "Infos" do
        attributes_table do
          row :name
          row :topic
          row :workshop_date
          row :animator
          row :co_animator
          row :workshop_address
          row :invitation_message
          row :workshop_participants
          row :tags
        end
      end
    end
  end

  controller do
    after_create do |workshop|
      message = workshop.invitation_message
      families = Family.tagged_with(workshop.tag_list.join(", "), any: true)
      parent_ids = workshop.participant_ids + Parent.tagged_with(workshop.tag_list.join(", "), any: true).pluck(:id) + families.pluck(:parent1_id) + families.pluck(:parent2_id)
      parent_ids.compact!

      parent_ids.each do |participant_id|
        WorkshopParticipation.create()
        response_link = Rails.application.routes.url_helpers.edit_workshop_participation_url(
          parent_id: participant_id,
          workshop_id: workshop.id
        )
        workshop.invitation_message = "#{message} Pour vous inscrire ou dire que vous ne venez pas, cliquer sur ce lien: #{response_link}"
        service = SpotHit::SendSmsService.new(
          participant_id,
          DateTime.current.middle_of_day,
          workshop.invitation_message
        ).call
        if service.errors.any?
          alert = service.errors.join("\n")
          raise StandardError, alert
        end
      rescue => e
        flash[:alert] = e.message.truncate(200)
      else
        flash[:notice] = "Invitations envoyées"
      end
    end
  end
end
