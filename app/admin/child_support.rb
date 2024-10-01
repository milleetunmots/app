ActiveAdmin.register ChildSupport do
  decorate_with ChildSupportDecorator

  has_better_csv
  has_paper_trail
  has_tags
  use_discard

  actions :all, except: [:new]

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  includes :children, :supporter

  index do
    selectable_column
    id_column
    column :children
    column :supporter if current_admin_user.admin? || current_admin_user.team_member? || current_admin_user.logistics_team?
    (0..5).each do |call_idx|
      column "Appel #{call_idx}" do |decorated|
        [
          decorated.send("call#{call_idx}_status_in_index"),
          decorated.send("call#{call_idx}_parent_progress_index")
        ].join(' ').html_safe
      end
    end
    column :availability
    column :call_infos
    column :groups
    column :tags do |model|
      model.current_admin_user = current_admin_user
      model.tags(context: 'tags')
    end
    column :actions do |item|
      div class: 'table_actions' do
        link_to('Modifier', edit_admin_child_support_path(item), class: 'edit_link member_link')
      end
    end
  end

  scope :all, group: :all

  scope(:mine, default: true, group: :supporter) { |scope| scope.supported_by(current_admin_user) }
  scope :without_supporter, group: :supporter, if: proc { !current_admin_user.caller? }

  scope :with_book_not_received
  scope :call_2_4, if: proc { !current_admin_user.caller? }
  scope :paused_or_stopped

  filter :availability, as: :string
  filter :call_infos, as: :string
  filter :group_id_in,
         as: :select,
         collection: proc { child_group_select_collection },
         input_html: { multiple: true, data: { select2: {} } },
         label: 'Cohorte'
  filter :without_parent_text_message_since,
         as: :datepicker,
         required: false,
         label: 'Parent sans SMS depuis'
  filter :source_in,
          as: :select,
          collection: proc { source_select_collection },
          input_html: { multiple: true, data: { select2: {} } },
          label: "Source d'inscription"
  filter :source_channel_in,
          as: :select,
          collection: proc { source_channel_select_collection },
          input_html: { multiple: true, data: { select2: {} } },
          label: "Canal d'inscription"
  filter :source_details_matches_any,
          as: :select,
          collection: proc { source_details_suggestions },
          input_html: { multiple: true, data: { select2: {} } },
          label: "Précisions sur l'origine"
  filter :should_be_read,
         input_html: { data: { select2: { width: '100%' } } }
  filter :book_not_received
  filter :is_bilingual, as: :check_boxes, collection: proc { is_bilingual_collection }
  filter :second_language
  filter :postal_code,
         as: :string
  filter :supporter,
         input_html: { data: { select2: {} } }
  (0..5).each do |call_idx|
    filter "call#{call_idx}_status_filter", as: :check_boxes,  label: "Statut de l'appel #{call_idx}", collection: proc { call_statuses_with_nil }
    filter "call#{call_idx}_duration"
    filter "call#{call_idx}_parent_progress_present",
           as: :boolean,
           label: "Note appel #{call_idx} présente"
    filter "call#{call_idx}_parent_progress",
           as: :select,
           collection: proc { child_support_call_parent_progress_select_collection },
           input_html: { multiple: true, data: { select2: {} } }
    # filter "call#{call_idx}_language_awareness",
    #   as: :select,
    #   collection: proc { child_support_call_language_awareness_select_collection },
    #   input_html: {multiple: true, data: {select2: {}}}
    filter "call#{call_idx}_sendings_benefits",
           as: :select,
           collection: proc { child_support_call_sendings_benefits_select_collection },
           input_html: { multiple: true, data: { select2: {} } }
    if call_idx == 1
      filter :books_quantity,
             as: :select,
             collection: proc { child_support_books_quantity },
             input_html: { multiple: true, data: { select2: {} } }
    end
    filter "call#{call_idx}_reading_frequency",
           as: :select,
           collection: proc { child_support_call_reading_frequency_select_collection },
           input_html: { multiple: true, data: { select2: {} } }
    filter "call#{call_idx}_tv_frequency",
           as: :select,
           collection: proc { child_support_call_tv_frequency_select_collection },
           input_html: { multiple: true, data: { select2: {} } }
  end
  filter :created_at
  filter :updated_at

  batch_action :assign_supporter, form: -> {
    {
      I18n.t('activerecord.attributes.child_support.supporter') => AdminUser.pluck(:name, :id)
    }
  } do |ids, inputs|
    batch_action_collection.find(ids).each do |child_support|
      supporter_id = inputs[I18n.t('activerecord.attributes.child_support.supporter')]
      child_support.supporter_id = supporter_id
      child_support.save!
    end
    redirect_to request.referer, notice: 'Responsable mis à jour'
  end

  batch_action :remove_book_not_received do |ids|
    child_supports = batch_action_collection.where(id: ids)
    child_supports.each { |child_support| child_support.update! book_not_received: [] }
    redirect_to request.referer, notice: 'Livres non reçus enlevés'
  end

  batch_action :check_should_be_read do |ids|
    child_supports = batch_action_collection.where(id: ids)
    child_supports.each { |child_support| child_support.should_be_read? ? next : child_support.update!(should_be_read: true) }
    redirect_to collection_path, notice: 'Témoignages marquants ajoutés.'
  end

  batch_action :uncheck_should_be_read do |ids|
    child_supports = batch_action_collection.where(id: ids)
    child_supports.each { |child_support| child_support.should_be_read? ? child_support.update!(should_be_read: false) : next }
    redirect_to collection_path, notice: 'Témoignages marquants retirés.'
  end

  batch_action :check_call_2_4 do |ids|
    child_supports = batch_action_collection.where(id: ids)
    child_supports.each { |child_support| child_support.to_call? ? next : child_support.update!(to_call: true) }
    redirect_to collection_path, notice: 'Appels 2 ou 4 ajoutés.'
  end

  batch_action :uncheck_call_2_4 do |ids|
    child_supports = batch_action_collection.where(id: ids)
    child_supports.each { |child_support| child_support.to_call? ? child_support.update!(to_call: false) : next }
    redirect_to collection_path, notice: 'Appels 2 ou 4 retirés.'
  end

  batch_action :remove_call_infos do |ids|
    child_supports = batch_action_collection.where(id: ids)
    child_supports.each { |child_support| child_support.update! call_infos: '' }
    redirect_to request.referer, notice: 'Informations éffacées'
  end

  batch_action :select_available_support_module do |ids|
    session[:select_available_support_module_ids] = ids
    redirect_to action: :select_available_support_module
  end

  collection_action :select_available_support_module do
    @ids = session.delete(:select_available_support_module_ids) || []
    @form_action = url_for(action: :perform_selecting_available_support_modules)
    @back_url = request.referer
    render 'active_admin/available_support_modules/add_available_modules'
  end

  collection_action :perform_selecting_available_support_modules, method: :post do
    ids = params[:ids]
    modules = params[:available_support_module_list]
    back_url = params[:back_url]

    ChildSupport.where(id: ids).each do |object|
      object.parent1_available_support_module_list = []
      object.parent2_available_support_module_list = []

      object.parent1_available_support_module_list += modules
      object.parent2_available_support_module_list += modules
      object.save(validate: false)
    end
    redirect_to back_url, notice: 'Modules disponibles ajoutés'
  end

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form(remote: true) do |f|
    f.semantic_errors(*f.object.errors.keys)
    f.inputs do
      f.input :id, as: :hidden, name: :id, value: f.object.id
      columns do
        column do
          f.input :supporter,
                  input_html: { data: { select2: {} } }
          # parents & children
          columns do
            # parents
            [
              [f.object.parent1, f.object.should_contact_parent1],
              [f.object.parent2, f.object.should_contact_parent2]
            ].each do |p|
              next if p[0].nil?

              parent = p[0].decorate
              should_contact_parent = p[1]

              column do
                render 'parent',
                       parent: parent,
                       should_contact_parent: should_contact_parent
              end
            end
            column do
              # children
              f.object.children.each do |c|
                child = c.decorate

                render 'child', child: child
              end
            end
          end
          columns style: 'margin-top:50px;' do
            column style: 'flex: 0 0 25%;' do
              f.input :is_bilingual,
                        collection: is_bilingual_collection,
                        input_html: { data: {} },
                        include_blank: false
            end
            column style: 'flex: 1;' do
              f.input :second_language
            end
          end

          columns do
            column do
              f.label :important_information
              f.input :important_information, label: false, input_html: { rows: 7, style: 'width: 100%; margin-top:20px;' }
            end
          end
        end
        column class: 'column flex-column' do
          available_support_module_input(f, :parent1_available_support_module_list, current_admin_user.caller?)
          available_support_module_input(f, :parent2_available_support_module_list, current_admin_user.caller?) unless resource.parent2.nil?
          div class: 'border' do
            span "Ces informations apparaissent dans l'index des suivis"
            f.input :availability, input_html: { style: 'width: 70%' }
            f.input :call_infos, input_html: { style: 'width: 70%' }
          end
          f.input :book_not_received,
                  collection: book_not_received_collection,
                  multiple: true,
                  input_html: { data: { select2: { tokenSeparators: [';'] } } }
          f.input :should_be_read
          f.input :to_call
          f.input :will_stay_in_group
          tags_input(f, context_list = 'tag_list', label: 'Tags fiche de suivi')
        end
      end
      tabs do
        (0..5).each do |call_idx|
          tab "Appel #{call_idx}" do
            columns do
              column do
                f.input "call#{call_idx}_status",
                        collection: call_status_collection,
                        input_html: { data: { select2: {} } }
                f.input "call#{call_idx}_duration", input_html: { style: 'font-weight: bold' }
                if call_idx.zero?
                  columns do
                    column do
                      f.label "Penses-tu que ce parent a déjà tous les outils et ressources suffisantes pour aider son enfant à développer son langage et n'a pas vraiment besoin de l'accompagnement 1001mots ?",
                        style: 'font-weight:bold;font-size:14px'
                    end
                    column do
                      f.input :family_support_should_be_stopped,
                        collection: ['Oui', 'Non', 'Je ne sais pas'],
                        input_html: { data: { select2: {} } },
                        label: false
                    end
                  end
                end
              end
              column do
                f.input "call#{call_idx}_status_details", input_html: { rows: 5, style: 'width: 70%' }
              end
            end

            columns style: 'justify-content:space-between;margin-top:10px' do
              if call_idx.zero?
                column max_width: '8%' do
                  f.label 'Informations questionnaire initial', style: 'font-weight:bold;font-size:14px'
                end
                column do
                  f.input :books_quantity,
                          as: :radio,
                          collection: child_support_books_quantity
                end
              end
              column do
                f.input "call#{call_idx}_reading_frequency",
                        as: :radio,
                        collection: child_support_call_reading_frequency_select_collection
              end
              column do
                f.input "call#{call_idx}_tv_frequency",
                        as: :radio,
                        collection: child_support_call_tv_frequency_select_collection
              end
            end

            f.input "call#{call_idx}_notes", input_html: { rows: 5, style: 'width: 100%' }

            f.input "call#{call_idx}_technical_information",
                        input_html: {
                          rows: 5,
                          style: 'width: 100%',
                          value: f.object.send("call#{call_idx}_technical_information").presence ||
                                 I18n.t('child_support.default.call_technical_information')
                        }

            columns do
              column do
                unless call_idx.zero?
                  f.input "call#{call_idx}_previous_call_goals", as: :text,
                          input_html: {
                            rows: 8,
                            readonly: true,
                            style: 'width: 70%',
                            value: f.object.send("call#{call_idx}_previous_call_goals").html_safe
                          }
                end

                unless call_idx.zero?
                  f.input "call#{call_idx}_goals_tracking",
                          input_html: {
                            rows: 8,
                            style: 'width: 70%'
                          }
                end

                f.input "call#{call_idx}_parent_actions",
                        input_html: {
                          rows: 8,
                          style: 'width: 70%'
                          # value: f.object.send("call#{call_idx}_parent_actions").presence ||
                          #   I18n.t("child_support.default.call_parent_actions")

                        }
                # f.input "call#{call_idx}_language_awareness",
                #   as: :radio,
                #   collection: child_support_call_language_awareness_select_collection
              end
              column do
                f.input "call#{call_idx}_goals_sms", input_html: { rows: 8, style: 'width: 70%', readonly: true }
                f.input "call#{call_idx}_goals", input_html: { rows: 8, style: 'width: 70%' }
                f.input "call#{call_idx}_language_development", input_html: { rows: 8, style: 'width: 70%' }
              end
            end
            columns do
              column do
                f.input "call#{call_idx}_parent_progress",
                        as: :radio,
                        collection: child_support_call_parent_progress_select_collection
              end
              column do
                f.input "call#{call_idx}_sendings_benefits",
                        as: :radio,
                        collection: child_support_call_sendings_benefits_select_collection
              end
              if [1, 2].include? call_idx
                column do
                  f.input "call#{call_idx}_family_progress",
                          as: :radio,
                          collection: child_support_call_family_progress_select_collection
                end
              end
              if [1, 2, 4].include? call_idx
                column do
                  f.input "call#{call_idx}_previous_goals_follow_up",
                          as: :radio,
                          collection: child_support_call_previous_goals_follow_up_select_collection
                end
              end
            end
            f.input "call#{call_idx}_sendings_benefits_details", input_html: { rows: 5, style: 'width: 100%' }
          end
        end
        if f.object.current_child
          %i[parent1 parent2].each do |k|
            next unless f.object.current_child.send(k)

            tab I18n.t("child_support.#{k}") do
              f.semantic_fields_for :current_child do |current_child_f|
                current_child_f.semantic_fields_for k do |parent_f|
                  parent_f.input :phone_number
                  parent_f.input :present_on_whatsapp
                  parent_f.input :follow_us_on_whatsapp
                  parent_f.input :present_on_facebook
                  parent_f.input :follow_us_on_facebook
                  parent_f.input :email
                  parent_f.input :letterbox_name
                  parent_f.input :address
                  parent_f.input :postal_code
                  parent_f.input :city_name
                  parent_f.input :is_ambassador
                  parent_f.input :job
                end
              end
            end
          end
        end
        if f.object.current_child
          tab f.object.current_child.decorate.name do
            f.semantic_fields_for :current_child do |current_child_f|
              current_child_f.input :gender,
                                    as: :radio,
                                    collection: child_gender_select_collection
              current_child_f.input :should_contact_parent1
              current_child_f.input :should_contact_parent2
            end
          end
          tab 'Historique' do
            render 'admin/events/history', events: f.object.parent_events.order(occurred_at: :desc).decorate
          end
        end
        tab 'Notes' do
          f.input :notes, as: :text
        end
      end
    end
    f.actions
  end

  base_attributes = %i[
    important_information
    supporter_id
    should_be_read
    is_bilingual
    second_language
    to_call
    books_quantity
    will_stay_in_group
    notes
    availability
    call_infos
    family_support_should_be_stopped
  ] + [tags_params.merge(book_not_received: [], parent1_available_support_module_list: [], parent2_available_support_module_list: [])]
  parent_attributes = %i[
    id
    gender first_name last_name phone_number email letterbox_name address postal_code city_name
    is_ambassador present_on_whatsapp present_on_facebook follow_us_on_whatsapp follow_us_on_facebook job
  ]
  current_child_attributes = [{
    current_child_attributes: [
      :id,
      :gender, :should_contact_parent1, :should_contact_parent2,
      {
        parent1_attributes: parent_attributes,
        parent2_attributes: parent_attributes
      }
    ]
  }]
  # block is mandatory here because ChildSupport.call_attributes hits DB
  permit_params do
    base_attributes + ChildSupport.call_attributes + current_child_attributes - %w[call0_goals_sms call1_goals_sms call2_goals_sms call3_goals_sms call4_goals_sms call5_goals_sms]
  end

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    tabs do
      tab I18n.t('child_support.base') do
        attributes_table title: I18n.t('child_support.base') do
          row :supporter
          row :parent1 do |decorated|
            if decorated.model.parent1
              render 'parent',
                     parent: decorated.model.parent1.decorate,
                     should_contact_parent: decorated.should_contact_parent1?
            end
          end
          row :parent2 do |decorated|
            if decorated.model.parent2
              render 'parent',
                     parent: decorated.model.parent2.decorate,
                     should_contact_parent: decorated.should_contact_parent2?
            end
          end
          row :children
          row :to_call
          # row :will_stay_in_group
          row :important_information
          row :availability
          row :call_infos
          row :book_not_received
          row :should_be_read
          row :display_is_bilingual
          row :second_language
          row :suggested_videos_sent_count if current_admin_user.admin? || current_admin_user.team_member? || current_admin_user.logistics_team?
          row :suggested_videos_sent_dates if current_admin_user.admin? || current_admin_user.team_member? || current_admin_user.logistics_team?
          row :tags do |model|
            model.current_admin_user = current_admin_user
            model.tags(context: 'tags')
          end
          row :created_at
          row :updated_at
        end
      end
      (0..5).each do |call_idx|
        tab "Appel #{call_idx}" do
          attributes_table title: "Appel #{call_idx}" do
            row "call#{call_idx}_status"
            row "call#{call_idx}_status_details"
            row "call#{call_idx}_duration"
            row "call#{call_idx}_technical_information"
            row "call#{call_idx}_parent_actions"
            # row "call#{call_idx}_language_awareness"
            row "call#{call_idx}_parent_progress"
            row "call#{call_idx}_sendings_benefits"
            row "call#{call_idx}_sendings_benefits_details"
            row :call2_family_progress if call_idx == 1
            if call_idx == 2
              row :call2_family_progress
              row :call2_previous_goals_follow_up
            end
            row "call#{call_idx}_language_development"
            row :books_quantity if call_idx.in?([0, 1])
            row "call#{call_idx}_reading_frequency"
            # row "call#{call_idx}_tv_frequency"
            row "call#{call_idx}_goals"
            row "call#{call_idx}_notes"
          end
        end
      end
      if resource.current_child
        tab 'Historique' do
          render 'admin/events/history', events: resource.parent_events.order(occurred_at: :desc).decorate
        end
      end
      tab 'Notes' do
        attributes_table title: 'Notes' do
          row :notes do
            simple_format resource.notes
          end
        end
      end
    end
  end

  csv do
    column :id
    column(:supporter) { |cs| cs.supporter_name }
    column(:parent1_gender) { |cs| Parent.human_attribute_name("gender.#{cs.parent1_gender}") }
    column :children_sources
    column :child_support_groups
    column :family_support_should_be_stopped
    column :children_land
    column :parent1_available_support_modules
    column :parent1_selected_support_modules
    column :parent2_available_support_modules
    column :parent2_selected_support_modules

    column :parent1_first_name
    column :parent1_last_name
    column :parent1_phone_number_national
    column :parent1_present_on_whatsapp
    column :parent1_follow_us_on_whatsapp
    column :parent1_present_on_facebook
    column :parent1_follow_us_on_facebook
    column :should_contact_parent1
    column :letterbox_name
    column :address
    column :city_name
    column :postal_code

    column(:parent2_gender) { |cs| cs.parent2_gender && Parent.human_attribute_name("gender.#{cs.parent2_gender}") }
    column :parent2_first_name
    column :parent2_last_name
    column :parent2_phone_number_national
    column :parent2_present_on_whatsapp
    column :parent2_follow_us_on_whatsapp
    column :parent2_present_on_facebook
    column :parent2_follow_us_on_facebook
    column :should_contact_parent2

    column :children_first_names
    column :children_last_names
    column :children_birthdates
    column :children_registration_months_range
    column :children_ages
    column :children_genders

    column :children_book_not_received
    column(:important_information) { |cs| cs.important_information_text }
    column :should_be_read
    column :is_bilingual
    column :second_language

    (0..5).each do |call_idx|
      column "call#{call_idx}_status"
      column "call#{call_idx}_status_details"
      column "call#{call_idx}_duration"
      column("call#{call_idx}_technical_information") do |cs|
        next if call_idx.zero?

        cs.send("call#{call_idx}_technical_information_text")
      end
      column("call#{call_idx}_parent_actions") do |cs|
        next if call_idx.zero?

        cs.send("call#{call_idx}_parent_actions_text")
      end
      # column "call#{call_idx}_language_awareness"
      column("call#{call_idx}_parent_progress")
      column("call#{call_idx}_sendings_benefits")
      column "call#{call_idx}_sendings_benefits_details"
      if call_idx == 2
        column :call2_family_progress
      end
      column("call#{call_idx}_language_development") do |cs|
        next if call_idx.zero?

        cs.send("call#{call_idx}_language_development_text")
      end
      column :books_quantity if call_idx.in?([0, 1])
      column("call#{call_idx}_reading_frequency")
      if call_idx.in?([1, 2, 4])
        column("call#{call_idx}_previous_goals_follow_up")
      end
      column("call#{call_idx}_goals_sms")
      column("call#{call_idx}_goals") do |cs|
        next if call_idx.zero?

        cs.send("call#{call_idx}_goals_text")
      end
      column("call#{call_idx}_notes") do |cs|
        next if call_idx.zero?

        cs.send("call#{call_idx}_notes_text")
      end
    end

    column :tag_list
    column :notes

    column :created_at
    column :updated_at
  end

  action_item :actions, only: %i[show edit] do
    dropdown_menu 'Actions' do
      item "Ajout d'un frère / soeur", %i[add_child admin child_support], { target: '_blank' }
      item "Ajout d'un parent", %i[add_parent admin child_support], { target: '_blank' } unless resource.decorate.model.parent2
      item "Autre tâche", url_for_new_task(resource.decorate), { target: '_blank' }
      item "Arrêter l'accompagnement", admin_stop_support_form_path(child_support_id: resource.decorate.model.id), { target: '_blank' }
      item "Potentiel parent bénévole",admin_volunteer_parent_form_path(child_support_id: resource.decorate.model.id, parent1_id: resource.decorate.model.parent1, parent2_id: resource.decorate.model.parent2), { target: '_blank' }
    end
  end

  member_action :add_child do
    redirect_to new_admin_child_path(
      parent1_id: resource.current_child.parent1_id,
      parent2_id: resource.current_child.parent2_id,
      should_contact_parent1: resource.current_child.should_contact_parent1,
      should_contact_parent2: resource.current_child.should_contact_parent2,
      source_id: Source.find_by(name: 'Je suis déjà inscrit à 1001mots', channel: 'bao').id,
      available_for_workshops: true
      )
  end

  member_action :add_parent do
    redirect_to new_admin_parent_path(
      address: resource.model.current_child.parent1.address,
      postal_code: resource.model.current_child.parent1.postal_code,
      city_name: resource.model.current_child.parent1.city_name,
      letterbox_name: resource.model.current_child.parent1.letterbox_name,
      parent2_child_ids: resource.model.current_child.sibling_ids,
      family_followed: true,
      parent2_creation: true
    )
  end

  action_item :other_family_child_supports,
              only: %i[show edit],
              if: proc { resource.has_other_family_child_supports? } do
    dropdown_menu 'Autres suivis' do
      resource.other_family_child_supports.each do |other_child_support|
        item other_child_support.decorate.dropdown_menu_item, url_for(id: other_child_support.id)
      end
    end
  end

  # action_item :send_select_module_message, only: [:show, :edit] do
  #   link_to I18n.t("child_support.send_select_module_message"), [:send_select_module_message, :admin, resource]
  # end

  # member_action :send_select_module_message do
  #
  #   service = ChildSupport::SelectModuleService.new(
  #     resource.model.current_child
  #   ).call
  #
  #   if service.errors.empty?
  #     redirect_to [:admin, resource], notice: 'SMS envoyé'
  #   else
  #     redirect_to [:admin, resource], alert: service.errors.join("\n")
  #   end
  # end

  action_item :tools, only: %i[show edit] do
    dropdown_menu 'Choisir un module' do
      item 'Pour le parent 1', %i[select_module_for_parent1 admin child_support], { target: '_blank' }
      item 'Pour le parent 2', %i[select_module_for_parent2 admin child_support], { target: '_blank' } unless resource.parent2.nil?
    end
  end

  action_item :clean_child_support, only: %i[show edit] do
    unless current_admin_user.caller?
      dropdown_menu 'Logistique' do
        item 'Nettoyer la fiche de suivi', [:clean_child_support, :admin, resource],
             { data: { confirm: 'Êtes-vous sûr de vouloir nettoyer la fiche de suivi ? Cette action est Irréversible, toutes les informations des appels vont être vidées et reportées danns les notes' }, method: 'GET' }
      end
    end
  end

  action_item :send_message, only: %i[show edit] do
    dropdown_menu 'Envoyer un SMS' do
      item 'Pour le parent 1', %i[send_message_to_parent1 admin child_support], { target: '_blank' }
      item 'Pour le parent 2', %i[send_message_to_parent2 admin child_support], { target: '_blank' } unless resource.parent2.nil?
    end
  end

  member_action :clean_child_support do
    resource.copy_fields(resource)

    ChildSupport.call_attributes.each do |attribute|
      next if attribute == 'call_infos'

      resource.assign_attributes({ attribute.to_sym => ChildSupport.column_defaults[attribute.to_s] })
    end
    resource.books_quantity = ChildSupport.column_defaults['books_quantity']
    resource.save
    redirect_to [:admin, resource], notice: 'Fiche de suivi nettoyée'
  end

  member_action :select_module_for_parent1 do
    children_support_module = ChildrenSupportModule.find_by(child: resource.model.current_child, parent: resource.model.parent1, is_programmed: false)
    if resource.parent1_available_support_module_list.nil? || resource.parent1_available_support_module_list.reject(&:blank?).empty?
      redirect_back(fallback_location: root_path, alert: "Aucun module disponible n'est choisi")
    elsif children_support_module
      redirect_to admin_children_support_module_path(id: children_support_module.id)
    else
      redirect_to new_admin_children_support_module_path(
        is_completed: false,
        parent_id: resource.model.parent1,
        child_id: resource.model.current_child,
        available_support_module_list: resource.parent1_available_support_module_list
      )
    end
  end

  member_action :select_module_for_parent2 do
    children_support_module = ChildrenSupportModule.find_by(child: resource.model.current_child, parent: resource.model.parent2, is_programmed: false)
    if resource.parent2_available_support_module_list.reject(&:blank?).empty?
      redirect_back(fallback_location: root_path, alert: "Aucun module disponible n'est choisi")
    elsif children_support_module
      redirect_to admin_children_support_module_path(id: children_support_module.id)
    else
      redirect_to new_admin_children_support_module_path(
        is_completed: false,
        parent_id: resource.model.parent2,
        child_id: resource.model.current_child,
        available_support_module_list: resource.parent2_available_support_module_list
      )
    end
  end

  member_action :send_message_to_parent1 do
    redirect_to admin_message_path(parent_id: resource.model.parent1.id, child_support_id: resource.model.id, parent_sc: resource.model.parent1.security_code)
  end

  member_action :send_message_to_parent2 do
    redirect_to admin_message_path(parent_id: resource.model.parent2&.id, child_support_id: resource.model.id, parent_sc: resource.model.parent1.security_code)
  end

  controller do
    def apply_filtering(chain)
      super(chain).distinct
    end
  end
end
