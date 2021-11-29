ActiveAdmin.register Child do

  decorate_with ChildDecorator

  has_better_csv
  has_paper_trail
  has_tags
  has_tasks
  use_discard

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  includes :parent1, :parent2, :child_support, :group

  index do
    div do
      render "index_top"
    end

    selectable_column
    id_column
    column :first_name do |model|
      model.admin_link(label: model.first_name)
    end
    column :last_name do |model|
      model.admin_link(label: model.last_name)
    end
    column :age, sortable: :birthdate
    column :parent1, sortable: :parent1_id
    column :parent2, sortable: :parent2_id
    column :postal_code
    column :child_support, sortable: :child_support_id do |model|
      model.child_support_status
    end
    column :group, sortable: :group_id
    column :group_status
    if :group_start && :group_end
      column :child_group_months
    end
    column :pmi_detail
    column :family_redirection_unique_visits
    column :tags
    column :created_at do |model|
      l model.created_at.to_date, format: :default
    end
    actions dropdown: true do |decorated|
      discard_links_args(decorated.model).each do |args|
        item *args
      end
    end
  end

  scope :all, default: true

  scope :without_group_and_not_waiting_second_group, group: :group
  scope :with_group, group: :group
  scope :waiting_second_group, group: :group

  scope :months_between_0_and_12, group: :months
  scope :months_between_12_and_24, group: :months
  scope :months_more_than_24, group: :months

  scope :with_support, group: :support
  scope :without_support, group: :support

  scope :without_parent_to_contact, group: :parent

  filter :gender,
    as: :check_boxes,
    collection: proc { child_gender_select_collection(with_unknown: true) }
  filter :first_name
  filter :last_name
  filter :postal_code,
    as: :string
  filter :birthdate
  filter :months,
    as: :numeric,
    filters: [:equals, :gteq, :lt]
  filter :registration_source,
    as: :select,
    collection: proc { child_registration_source_select_collection },
    input_html: {multiple: true, data: {select2: {}}},
    label: "Origine"
  filter :pmi_detail,
    as: :select,
    collection: proc { child_registration_pmi_detail_collection },
    input_html: {multiple: true, data: {select2: {}}}
  filter :registration_source_details_matches_any,
    as: :select,
    collection: proc { child_registration_source_details_suggestions },
    input_html: {multiple: true, data: {select2: {}}},
    label: "Précisions sur l'origine"
  filter :group_id_in,
    as: :select,
    collection: proc { child_group_select_collection },
    input_html: {multiple: true, data: {select2: {}}},
    label: "Cohorte"
  filter :group_status,
    as: :select,
    collection: proc {child_group_status_select_collection} ,
    input_html: {multiple: true, data: {select2: {}}}
  filter :group_start,
    as: :datepicker,
      required: false,
      label: "Début de l'accompagnement"
  filter :group_end,
    as: :datepicker,
    required: false,
    label: "Fin de l'accompagnement"
  filter :active_group_id_in,
    as: :select,
    collection: proc { child_group_select_collection },
    input_html: {multiple: true, data: {select2: {}}},
    label: "Cohorte active"
  filter :without_parent_text_message_since,
    as: :datepicker,
    required: false,
    label: "Parent sans SMS depuis"
  filter :family_redirection_urls_count
  filter :family_redirection_url_visits_count
  filter :family_redirection_url_unique_visits_count
  filter :family_redirection_unique_visit_rate
  filter :family_redirection_unique_visits
  filter :src_url
  filter :created_at
  filter :updated_at

  batch_action :add_tags do |ids|
    session[:add_tags_ids] = ids
    redirect_to action: :add_tags
  end

  collection_action :add_tags do
    @klass = collection.object.klass
    @ids = session.delete(:add_tags_ids) || []
    @form_action = url_for(action: :perform_adding_tags)
    @back_url = request.referer
    render "active_admin/tags/add_tags"
  end

  collection_action :perform_adding_tags, method: :post do
    ids = params[:ids]
    tags = params[:tag_list]
    back_url = params[:back_url]

    Child.where(id: ids).each do |child|
      child.tag_list.add(tags)
      child.save(validate: false)
      child.child_support&.update! tag_list: child.tag_list
      child.parent1&.update! tag_list: (child.parent1&.tag_list + child.tag_list).uniq
      child.parent2&.update! tag_list: (child.parent2&.tag_list + child.tag_list).uniq
    end
    redirect_to back_url, notice: "Tags ajoutés"
  end

  batch_action :create_support do |ids|
    batch_action_collection.find(ids).each do |child|
      next if already_existing_child_support = child.child_support
      child.create_support!
    end
    redirect_to collection_path, notice: I18n.t("child.supports_created")
  end

  batch_action :add_to_group, form: -> {
    {
      I18n.t("activerecord.models.group") => Group.not_ended.order(:name).pluck(:name, :id)
    }
  } do |ids, inputs|
    if batch_action_collection.where(id: ids).with_group.any?
      flash[:error] = "Certains enfants sont déjà dans une cohorte"
      redirect_to request.referer
    else
      group = Group.find(inputs[I18n.t("activerecord.models.group")])
      batch_action_collection.where(id: ids).update_all(
        group_id: group.id,
        group_status: "active",
        group_start: group.started_at
      )
      redirect_to request.referer, notice: "Enfants ajoutés à la cohorte"
    end
  end

  batch_action :quit_group do |ids|
    batch_action_collection.where(id: ids).update_all(group_status: "paused")
    redirect_to request.referer, notice: "Modification effectuée"
  end

  batch_action :create_redirection_url, form: -> {
    {
      I18n.t("activerecord.models.medium") => Medium.for_redirections.order(:name).kept.pluck(:name, :id)
    }
  } do |ids, inputs|
    children = batch_action_collection.where(id: ids)

    if children.without_parent_to_contact.any?
      flash[:error] = "Certains enfants n'ont aucun parent à contacter"
      redirect_to request.referer
    else
      medium = Medium.find(inputs[I18n.t("activerecord.models.medium")])

      redirection_target = RedirectionTarget.where(medium: medium).first_or_create!

      latest_parent1_id = nil
      children.order(:parent1_id).each do |child|
        next if latest_parent1_id == child.parent1_id
        latest_parent1_id = child.parent1_id

        if child.should_contact_parent1?
          RedirectionUrl.create!(
            redirection_target: redirection_target,
            parent_id: child.parent1_id,
            child: child
          )
        end

        if child.should_contact_parent2? && child.parent2_id
          RedirectionUrl.create!(
            redirection_target: redirection_target,
            parent_id: child.parent2_id,
            child: child
          )
        end
      end
      redirect_to redirection_target.decorate.redirection_urls_path, notice: "URL courtes créées"
    end
  end

  batch_action :addresses_pdf do |ids|
    @children = batch_action_collection.where(id: ids).decorate
    @debug = params.key?("debug")
    render pdf: "etiquettes",
           disposition: "attachment",
           template: "admin/children/addresses_pdf",
           layout: "pdf",
           margin: {
             top: 3,
             bottom: 0,
             left: 1,
             right: 0
           },
           show_as_html: @debug,
           disable_local_file_access: false,
           enable_local_file_access: true,
           progress: proc { |output| puts output }
  end

  batch_action :generate_buzz_expert do |ids|
    @children = batch_action_collection.where(id: ids)

    service = BuzzExpert::ExportChildrenService.new(children: @children).call
    if service.errors.any?
      puts "Error: #{service.errors}"
      flash[:error] = "Une erreur est survenue: #{service.errors.join(', ')}"
      redirect_to request.referer
    else
      send_data service.csv, filename: "Buzz-Expert - #{csv_filename}"
    end
  end

  batch_action :generate_quit_sms do |ids|
    @children = batch_action_collection.where(id: ids)

    if @children.without_parent_to_contact.any?
      flash[:error] = "Certains enfants n'ont aucun parent à contacter"
      redirect_to request.referer
    end

    latest_parent_id = nil
    begin
      @children.order(:parent1_id).each do |child|
        next if child.child_support&.will_stay_in_group?
        next if latest_parent_id == child.parent1_id
        latest_parent_id = child.parent1_id

        next_saturday = Time.now.beginning_of_week.next_day(5).change({hour: 14, min: 30, sec: 0})
        quit_link = Rails.application.routes.url_helpers.edit_child_url(
          id: child.id,
          security_code: child.security_code
        )
        message = "Bonjour ! Ca fait 4 mois que je vous envoie des SMS pour votre enfant. Bravo pour tout ce que vous faites pour lui :) Voulez vous continuer à recevoir ces SMS et livres ? Cliquez sur le lien ci-dessous et répondez OUI ! Ca reprendra prochainement ! Je vous souhaite de beaux moments avec vos enfants :) #{quit_link}"

        service = SpotHit::SendSmsService.new(
          [latest_parent_id],
          next_saturday.to_i,
          message
        ).call
        if service.errors.any?
          alert = service.errors.join("\n")
          raise StandardError, alert
        else
          child.update! group_status: "paused"
        end
      end
    rescue StandardError => e
      redirect_back(fallback_location: root_path, alert: e.message.truncate(200))
    else
      flash[:notice] = "Message de continuation envoyé"
      redirect_to admin_sent_by_app_text_messages_url
    end
  end

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs do
      f.input :parent1,
        collection: child_parent_select_collection,
        input_html: {data: {select2: {}}}
      f.input :should_contact_parent1
      f.input :parent2,
        collection: child_parent_select_collection,
        input_html: {data: {select2: {}}}
      f.input :should_contact_parent2
      f.input :gender,
        as: :radio,
        collection: child_gender_select_collection
      f.input :first_name
      f.input :last_name
      f.input :birthdate,
        as: :datepicker,
        datepicker_options: {
          min_date: Child.min_birthdate,
          max_date: Child.max_birthdate
        }
      f.input :registration_source,
        collection: child_registration_source_select_collection,
        input_html: {data: {select2: {}}}
      f.input :pmi_detail,
        collection: child_registration_pmi_detail_collection,
        input_html: {data: {select2: {}}}
      f.input :registration_source_details
      f.input :group,
        collection: child_group_select_collection,
        input_html: {data: {select2: {}}}
      f.input :group_status,
        collection: child_group_status_select_collection,
        input_html: {data: {select2: {}}}
      tags_input(f)
    end
    f.actions
  end

  permit_params :parent1_id, :parent2_id, :group_id,
    :should_contact_parent1, :should_contact_parent2,
    :gender, :first_name, :last_name, :birthdate,
    :registration_source, :registration_source_details, :pmi_detail, :group_status,
    tags_params

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    tabs do
      tab "Infos" do
        attributes_table do
          row :parent1
          row :should_contact_parent1
          row :parent2
          row :should_contact_parent2
          row :first_name
          row :last_name
          row :birthdate
          row :age
          row :gender do |decorated|
            decorated.gender_status
          end
          row :registration_source
          row :registration_source_details
          row :pmi_detail
          row :group
          row :group_status
          row :group_start
          row :group_end
          row :child_group_months
          row :family_text_messages_count
          row :family_redirection_urls_count
          row :family_redirection_url_visits_count
          row :family_redirection_url_unique_visits_count
          row :family_redirection_unique_visit_rate
          row :family_redirection_visit_rate
          row :security_code do |decorated|
            decorated.security_code
          end
          row :public_edit_url do |decorated|
            decorated.public_edit_link(target: "_blank")
          end
          row :tags
          row :src_url
          row :created_at
          row :updated_at
        end
      end
      tab "Historique" do
        render "admin/events/history", events: resource.parent_events.order(occurred_at: :desc).decorate
      end
    end
  end

  action_item :show_support,
    only: :show,
    if: proc { resource.child_support } do
    link_to I18n.t("child.show_support_link"), [:admin, resource.child_support]
  end
  action_item :create_support,
    only: :show,
    if: proc { !resource.child_support } do
    link_to I18n.t("child.create_support_link"), [:create_support, :admin, resource]
  end
  member_action :create_support do
    if already_existing_child_support = resource.child_support
      redirect_to [:admin, already_existing_child_support], notice: I18n.t("child.support_already_existed")
    else
      resource.create_support!
      redirect_to [:edit, :admin, resource.child_support]
    end
  end
  action_item :quit_group,
    only: :show,
    if: proc { resource.group && %w[paused active].include?(resource.model.group_status) } do
    link_to "Quitter la cohorte", [:quit_group, :admin, resource]
  end
  member_action :quit_group do
    resource.update_attribute :group_status, "stopped"
    resource.update_attribute :group_end, resource.model.group.ended_at&.past? ? resource.model.group.ended_at : Time.now
    redirect_to [:admin, resource]
  end

  # ---------------------------------------------------------------------------
  # IMPORT
  # ---------------------------------------------------------------------------

  action_item :new_import,
    only: :index do
    link_to I18n.t("child.new_import_link"), [:new_import, :admin, :children]
  end
  collection_action :new_import do
    @import_action = perform_import_admin_children_path
  end
  collection_action :perform_import, method: :post do
    @csv_file = params[:import][:csv_file]

    service = ChildrenImportService.new(csv_file: @csv_file).call

    if service.errors.empty?
      redirect_to admin_children_path, notice: "Import terminé"
    else
      @import_action = perform_import_admin_children_path
      @errors = service.errors
      render :new_import
    end
  end

  # ---------------------------------------------------------------------------
  # TOOLS
  # ---------------------------------------------------------------------------

  action_item :tools,
    only: :index do
    dropdown_menu "Outils" do
      item "Nettoyer les précisions sur l'origine",
        [:new_clean_registration_source_details, :admin, :children]
    end
  end
  collection_action :new_clean_registration_source_details do
    @values = Child.registration_source_details_map.to_a.sort_by do |o|
      I18n.transliterate(
        o.first.unicode_normalize
      ).downcase.gsub(/[\s-]+/, " ").strip
    end
    @perform_action = perform_clean_registration_source_details_admin_children_path
  end

  collection_action :perform_clean_registration_source_details, method: :post do
    params[:changes].each do |idx, change|
      wanted_value = change[:wanted]
      existing_values = change[:existing]
      Child.where(
        registration_source_details: existing_values
      ).update_all(
        registration_source_details: wanted_value
      )
    end
    redirect_to admin_children_path, notice: "Nettoyage effectué"
  end

  action_item :view do
    link_to "Nouveau parent", new_admin_parent_path, target: "_blank"
  end

  # ---------------------------------------------------------------------------
  # CSV EXPORT
  # ---------------------------------------------------------------------------

  csv do
    column :id

    column :first_name
    column :last_name
    column :birthdate
    column :registration_months_range
    column :age
    column :gender
    column :letterbox_name
    column :address
    column :city_name
    column :postal_code

    column :child_group_name

    column :parent1_gender
    column :parent1_first_name
    column :parent1_last_name
    column :parent1_email
    column :parent1_phone_number_national
    column :parent1_is_lycamobile
    column :should_contact_parent1

    column :parent2_gender
    column :parent2_first_name
    column :parent2_last_name
    column :parent2_email
    column :parent2_phone_number_national
    column :parent2_is_lycamobile
    column :should_contact_parent2

    column :registration_source
    column :pmi_detail
    column :registration_source_details

    column :group_status

    column :family_text_messages_count

    column :family_redirection_urls_count
    column :family_redirection_url_visits_count
    column :family_redirection_url_unique_visits_count
    column :family_redirection_unique_visit_rate
    column :family_redirection_visit_rate

    column :tag_list

    column :created_at
    column :updated_at
  end

  controller do
    after_save do |child|
      child.update! group_start: child.group.started_at if child.group && %w[active stopped paused].include?(child.group_status) && group_start.nil?
      child.update!(group_end: child.group.ended_at, group_status: "stopped") if child.group&.ended_at&.past?
      child.child_support&.update! tag_list: child.tag_list
      child.parent1&.update! tag_list: (child.parent1&.tag_list + child.tag_list).uniq
      child.parent2&.update! tag_list: (child.parent2&.tag_list + child.tag_list).uniq
    end

    def csv_filename
      filter_name = params.fetch(:q, {}).fetch(:active_group_id_in, []).map do |group_id|
        Group.find_by_id(group_id)&.name
      end.join(",")

      [
        Child.model_name.human.pluralize,
        current_scope.name,
        filter_name.presence,
        Time.zone.now.to_date.to_s(:default)
      ].compact.join(" - ") + ".csv"
    end
  end
end
