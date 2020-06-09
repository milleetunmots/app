ActiveAdmin.register ChildSupport do

  decorate_with ChildSupportDecorator

  has_better_csv
  has_paper_trail
  has_tasks
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
    column :supporter, sortable: :supporter_id
    column :should_be_read
    column I18n.t('child_support.call1') do |model|
      [model.call1_status, model.call1_parent_progress_index].join(' ').html_safe
    end
    column I18n.t('child_support.call2') do |model|
      [model.call2_status, model.call2_parent_progress_index].join(' ').html_safe
    end
    column I18n.t('child_support.call3') do |model|
      [model.call3_status, model.call3_parent_progress_index].join(' ').html_safe
    end
    column :groups
    column :registration_sources
    column :created_at do |model|
      l model.created_at.to_date, format: :default
    end
    actions do |decorated|
      discard_links(decorated.model, class: 'member_link')
    end
  end

  scope(:mine, default: true) { |scope| scope.supported_by(current_admin_user) }
  scope :all

  scope :with_book_not_received

  filter :unpaused_group_id_in,
         as: :select,
         collection: proc { child_group_select_collection },
         input_html: { multiple: true, data: { select2: {} } },
         label: 'Cohorte active'
  filter :without_parent_text_message_since,
         as: :datepicker,
         required: false,
         label: 'Parent sans SMS depuis'
  filter :registration_sources,
         as: :select,
         collection: proc { child_registration_source_select_collection },
         input_html: { multiple: true, data: { select2: {} } }
  filter :should_be_read,
         input_html: { data: { select2: { width: '100%' } } }
  filter :book_not_received
  filter :is_bilingual
  filter :second_language
  filter :postal_code,
         as: :string
  filter :supporter,
         input_html: { data: { select2: {} } }
  filter :call1_status
  filter :call1_duration
  filter :call1_parent_progress_present,
         as: :boolean,
         label: proc { I18n.t('child_support.call1_parent_progress_present') }
  filter :call1_parent_progress,
         as: :select,
         collection: proc { child_support_call1_parent_progress_select_collection },
         input_html: { multiple: true, data: { select2: {} } }
  filter :call1_language_awareness,
         as: :select,
         collection: proc { child_support_call1_language_awareness_select_collection },
         input_html: { multiple: true, data: { select2: {} } }
  filter :call1_books_quantity
  filter :call1_reading_frequency,
         as: :select,
         collection: proc { child_support_call1_reading_frequency_select_collection },
         input_html: { multiple: true, data: { select2: {} } }
  filter :call2_status
  filter :call2_duration
  filter :call2_parent_progress_present,
         as: :boolean,
         label: proc { I18n.t('child_support.call2_parent_progress_present') }
  filter :call2_parent_progress,
         as: :select,
         collection: proc { child_support_call2_parent_progress_select_collection },
         input_html: { multiple: true, data: { select2: {} } }
  filter :call2_language_awareness,
         as: :select,
         collection: proc { child_support_call2_language_awareness_select_collection },
         input_html: { multiple: true, data: { select2: {} } }
  filter :call2_sendings_benefits,
         as: :select,
         collection: proc { child_support_call2_sendings_benefits_select_collection },
         input_html: { multiple: true, data: { select2: {} } }
  filter :call2_reading_frequency,
         as: :select,
         collection: proc { child_support_call2_reading_frequency_select_collection },
         input_html: { multiple: true, data: { select2: {} } }
  filter :call3_status
  filter :call3_duration
  filter :call3_parent_progress_present,
         as: :boolean,
         label: proc { I18n.t('child_support.call3_parent_progress_present') }
  filter :call3_parent_progress,
         as: :select,
         collection: proc { child_support_call3_parent_progress_select_collection },
         input_html: { multiple: true, data: { select2: {} } }
  filter :call3_language_awareness,
         as: :select,
         collection: proc { child_support_call3_language_awareness_select_collection },
         input_html: { multiple: true, data: { select2: {} } }
  filter :call3_sendings_benefits,
         as: :select,
         collection: proc { child_support_call3_sendings_benefits_select_collection },
         input_html: { multiple: true, data: { select2: {} } }
  filter :call3_reading_frequency,
         as: :select,
         collection: proc { child_support_call3_reading_frequency_select_collection },
         input_html: { multiple: true, data: { select2: {} } }
  filter :created_at
  filter :updated_at

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form(remote: true) do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs do
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
        end
        column do
          f.label :important_information
          f.input :important_information, label: false, input_html: { rows: 3, style: 'width: 100%' }
          columns do
            column do
              f.input :is_bilingual
              f.input :second_language
            end
            column do
              f.input :should_be_read
              f.input :book_not_received
            end
          end
        end
      end
      tabs do
        tab I18n.t('child_support.call1') do
          columns do
            column do
              f.input :call1_status, input_html: { style: 'width: 70%' }
              f.input :call1_duration, input_html: { style: 'width: 70%' }
            end
            column do
              f.input :call1_status_details, input_html: { rows: 5, style: 'width: 70%' }
            end
          end
          columns do
            column do
              f.input :call1_parent_actions,
                      input_html: {
                        rows: 8,
                        style: 'width: 70%',
                        value: f.object.call1_parent_actions.presence || (
                          I18n.t('child_support.default.call1_parent_actions')
                        )
                      }
              f.input :call1_language_awareness,
                      as: :radio,
                      collection: child_support_call1_language_awareness_select_collection
              f.input :call1_parent_progress,
                      as: :radio,
                      collection: child_support_call1_parent_progress_select_collection
              f.input :call1_books_quantity, input_html: { style: 'width: 70%' }
              f.input :call1_reading_frequency,
                      as: :radio,
                      collection: child_support_call1_reading_frequency_select_collection
            end
            column do
              f.input :call1_language_development, input_html: { rows: 8, style: 'width: 70%' }
              f.input :call1_goals, input_html: { rows: 8, style: 'width: 70%' }
              f.input :call1_notes,
                      input_html: {
                        rows: 8,
                        style: 'width: 70%',
                        value: f.object.call1_notes.presence || (
                          I18n.t('child_support.default.call1_notes')
                        )
                      }
            end
          end
        end
        tab I18n.t('child_support.call2') do
          columns do
            column do
              f.input :call2_status, input_html: { style: 'width: 70%' }
              f.input :call2_duration, input_html: { style: 'width: 70%' }
            end
            column do
              f.input :call2_status_details, input_html: { rows: 5, style: 'width: 70%' }
            end
          end
          columns do
            column do
              f.input :call2_technical_information,
                      input_html: {
                        rows: 8,
                        style: 'width: 70%',
                        value: f.object.call2_technical_information.presence || (
                          I18n.t('child_support.default.call2_technical_information')
                        )
                      }
              f.input :call2_parent_actions,
                      input_html: {
                        rows: 8,
                        style: 'width: 70%',
                        value: f.object.call2_parent_actions.presence || (
                          I18n.t('child_support.default.call2_parent_actions')
                        )
                      }
              f.input :call2_language_awareness,
                      as: :radio,
                      collection: child_support_call2_language_awareness_select_collection
              f.input :call2_parent_progress,
                      as: :radio,
                      collection: child_support_call2_parent_progress_select_collection
              f.input :call2_reading_frequency,
                      as: :radio,
                      collection: child_support_call2_reading_frequency_select_collection
              f.input :call2_sendings_benefits,
                      as: :radio,
                      collection: child_support_call2_sendings_benefits_select_collection
              f.input :call2_sendings_benefits_details, input_html: { rows: 5, style: 'width: 70%' }
            end
            column do
              f.input :call2_language_development, input_html: { rows: 8, style: 'width: 70%' }
              f.input :call2_goals, input_html: { rows: 8, style: 'width: 70%' }
              f.input :call2_notes,
                      input_html: {
                        rows: 8,
                        style: 'width: 70%',
                        value: f.object.call2_notes.presence || (
                          I18n.t('child_support.default.call2_notes')
                        )
                      }
            end
          end
        end
        tab I18n.t('child_support.call3') do
          columns do
            column do
              f.input :call3_status, input_html: { style: 'width: 70%' }
              f.input :call3_duration, input_html: { style: 'width: 70%' }
            end
            column do
              f.input :call3_status_details, input_html: { rows: 5, style: 'width: 70%' }
            end
          end
          columns do
            column do
              f.input :call3_technical_information,
                      input_html: {
                        rows: 8,
                        style: 'width: 70%',
                        value: f.object.call3_technical_information.presence || (
                          I18n.t('child_support.default.call3_technical_information')
                        )
                      }
              f.input :call3_parent_actions,
                      input_html: {
                        rows: 8,
                        style: 'width: 70%',
                        value: f.object.call3_parent_actions.presence || (
                          I18n.t('child_support.default.call3_parent_actions')
                        )
                      }
              f.input :call3_language_awareness,
                      as: :radio,
                      collection: child_support_call3_language_awareness_select_collection
              f.input :call3_parent_progress,
                      as: :radio,
                      collection: child_support_call3_parent_progress_select_collection
              f.input :call3_reading_frequency,
                      as: :radio,
                      collection: child_support_call3_reading_frequency_select_collection
              f.input :call3_sendings_benefits,
                      as: :radio,
                      collection: child_support_call3_sendings_benefits_select_collection
              f.input :call3_sendings_benefits_details, input_html: { rows: 5, style: 'width: 70%' }
            end
            column do
              f.input :call3_language_development, input_html: { rows: 8, style: 'width: 70%' }
              f.input :call3_goals, input_html: { rows: 8, style: 'width: 70%' }
              f.input :call3_notes,
                      input_html: {
                        rows: 8,
                        style: 'width: 70%',
                        value: f.object.call3_notes.presence || (
                          I18n.t('child_support.default.call3_notes')
                        )
                      }
            end
          end
        end
        if f.object.first_child
          %i(parent1 parent2).each do |k|
            if f.object.first_child.send(k)
              tab I18n.t("child_support.#{k}") do
                f.semantic_fields_for :first_child do |first_child_f|
                  first_child_f.semantic_fields_for k do |parent_f|
                    parent_f.input :phone_number
                    parent_f.input :is_lycamobile
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
        end
        if f.object.first_child
          tab f.object.first_child.decorate.name do
            f.semantic_fields_for :first_child do |first_child_f|
              first_child_f.input :gender,
                                  as: :radio,
                                  collection: child_gender_select_collection(with_unknown: true)
              first_child_f.input :should_contact_parent1
              first_child_f.input :should_contact_parent2
              first_child_f.input :registration_source,
                                  collection: child_registration_source_select_collection,
                                  input_html: { data: { select2: {} } }
              first_child_f.input :registration_source_details
            end
          end
          tab 'Historique' do
            render 'admin/events/history', events: f.object.parent_events.order(occurred_at: :desc).decorate
          end
        end
      end
    end
    f.actions
  end

  parent_attributes = %i(
    id
    gender first_name last_name phone_number email letterbox_name address postal_code city_name
    is_ambassador is_lycamobile job
  )
  permit_params :important_information, :supporter_id,
                :should_be_read, :book_not_received,
                :is_bilingual, :second_language,
                :call1_duration, :call1_status, :call1_status_details,
                :call1_parent_actions, :call1_parent_progress,
                :call1_language_development, :call1_notes,
                :call1_books_quantity, :call1_reading_frequency,
                :call1_goals, :call1_language_awareness,
                :call2_duration, :call2_status, :call2_status_details,
                :call2_technical_information, :call2_parent_actions,
                :call2_language_development,
                :call2_language_awareness, :call2_parent_progress,
                :call2_sendings_benefits, :call2_sendings_benefits_details,
                :call2_goals, :call2_notes, :call2_reading_frequency,
                :call3_duration, :call3_status, :call3_status_details,
                :call3_technical_information, :call3_parent_actions,
                :call3_sendings_benefits, :call3_sendings_benefits_details,
                :call3_language_development, :call3_language_awareness,
                :call3_parent_progress, :call3_goals, :call3_notes,
                :call3_reading_frequency,
                first_child_attributes: [
                  :id,
                  :gender, :should_contact_parent1, :should_contact_parent2,
                  :registration_source, :registration_source_details,
                  {
                    parent1_attributes: parent_attributes,
                    parent2_attributes: parent_attributes
                  }
                ]

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
          row :important_information
          row :book_not_received
          row :should_be_read
          row :is_bilingual
          row :second_language
          row :created_at
          row :updated_at
        end
      end
      tab I18n.t('child_support.call1') do
        attributes_table title: I18n.t('child_support.call1') do
          row :call1_status
          row :call1_status_details
          row :call1_duration
          row :call1_parent_actions
          row :call1_language_awareness
          row :call1_parent_progress
          row :call1_language_development
          row :call1_books_quantity
          row :call1_reading_frequency
          row :call1_goals
          row :call1_notes
        end
      end
      tab I18n.t('child_support.call2') do
        attributes_table title: I18n.t('child_support.call2') do
          row :call2_status
          row :call2_status_details
          row :call2_duration
          row :call2_technical_information
          row :call2_parent_actions
          row :call2_language_awareness
          row :call2_parent_progress
          row :call2_sendings_benefits
          row :call2_sendings_benefits_details
          row :call2_language_development
          row :call2_reading_frequency
          row :call2_goals
          row :call2_notes
        end
      end
      tab I18n.t('child_support.call3') do
        attributes_table title: I18n.t('child_support.call3') do
          row :call3_status
          row :call3_status_details
          row :call3_duration
          row :call3_technical_information
          row :call3_parent_actions
          row :call3_language_awareness
          row :call3_parent_progress
          row :call3_sendings_benefits
          row :call3_sendings_benefits_details
          row :call3_language_development
          row :call3_reading_frequency
          row :call3_goals
          row :call3_notes
        end
      end
      if resource.first_child
        tab 'Historique' do
          render 'admin/events/history', events: resource.parent_events.order(occurred_at: :desc).decorate
        end
      end
    end
  end

  csv do
    column :id
    column(:supporter) { |cs| cs.supporter_name }

    column(:parent1_gender) { |cs| Parent.human_attribute_name("gender.#{cs.parent1_gender}") }
    column :parent1_first_name
    column :parent1_last_name
    column :parent1_phone_number_national
    column :parent1_is_lycamobile
    column :should_contact_parent1
    column :letterbox_name
    column :address
    column :city_name
    column :postal_code

    column(:parent2_gender) { |cs| cs.parent2_gender && Parent.human_attribute_name("gender.#{cs.parent2_gender}") }
    column :parent2_first_name
    column :parent2_last_name
    column :parent2_phone_number_national
    column :parent2_is_lycamobile
    column :should_contact_parent2

    column :children_first_names
    column :children_last_names
    column :children_birthdates
    column :children_ages
    column :children_genders

    column :book_not_received
    column(:important_information) { |cs| cs.important_information_text }
    column :should_be_read
    column :is_bilingual
    column :second_language

    column :call1_status
    column :call1_status_details
    column :call1_duration
    column(:call1_parent_actions) { |cs| cs.call1_parent_actions_text }
    column :call1_language_awareness
    column :call1_parent_progress
    column(:call1_language_development) { |cs| cs.call1_language_development_text }
    column :call1_books_quantity
    column :call1_reading_frequency
    column(:call1_goals) { |cs| cs.call1_goals_text }
    column(:call1_notes) { |cs| cs.call1_notes_text }

    column :call2_status
    column :call2_status_details
    column :call2_duration
    column(:call2_technical_information) { |cs| cs.call2_technical_information_text }
    column(:call2_parent_actions) { |cs| cs.call2_parent_actions_text }
    column :call2_language_awareness
    column :call2_parent_progress
    column :call2_sendings_benefits
    column :call2_sendings_benefits_details
    column(:call2_language_development) { |cs| cs.call2_language_development_text }
    column :call2_reading_frequency
    column(:call2_goals) { |cs| cs.call2_goals_text }
    column(:call2_notes) { |cs| cs.call2_notes_text }

    column :call3_status
    column :call3_status_details
    column :call3_duration
    column(:call3_technical_information) { |cs| cs.call3_technical_information_text }
    column(:call3_parent_actions) { |cs| cs.call3_parent_actions_text }
    column :call3_language_awareness
    column :call3_parent_progress
    column :call3_sendings_benefits
    column :call3_sendings_benefits_details
    column(:call3_language_development) { |cs| cs.call3_language_development_text }
    column :call3_reading_frequency
    column(:call3_goals) { |cs| cs.call3_goals_text }
    column(:call3_notes) { |cs| cs.call3_notes_text }

    column :created_at
    column :updated_at
  end

  action_item :other_family_child_supports,
              only: %i(show edit),
              if: proc { resource.has_other_family_child_supports? } do
    dropdown_menu 'Autres suivis' do
      resource.other_family_child_supports.each do |other_child_support|
        item other_child_support.decorate.dropdown_menu_item, url_for(id: other_child_support.id)
      end
    end
  end

end
