ActiveAdmin.register ChildSupport do

  decorate_with ChildSupportDecorator

  has_better_csv
  has_paper_trail
  has_tags
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
    (1..5).each do |call_idx|
      column "Appel #{call_idx}" do |decorated|
        [
          decorated.send("call#{call_idx}_status"),
          decorated.send("call#{call_idx}_parent_progress_index")
        ].join(" ").html_safe
      end
    end
    column :groups
    column :registration_sources
    column :created_at do |decorated|
      l decorated.created_at.to_date, format: :default
    end
    column :to_call
    actions dropdown: true do |decorated|
      discard_links_args(decorated.model).each do |args|
        item *args
      end
    end
  end

  scope :all, group: :all

  scope(:mine, default: true, group: :supporter) { |scope| scope.supported_by(current_admin_user) }
  scope :without_supporter, group: :supporter

  scope :with_book_not_received
  scope :call_2_4, group: :call

  filter :group_id_in,
    as: :select,
    collection: proc { child_group_select_collection },
    input_html: {multiple: true, data: {select2: {}}},
    label: "Cohorte"
  filter :unpaused_group_id_in,
    as: :select,
    collection: proc { child_group_select_collection },
    input_html: {multiple: true, data: {select2: {}}},
    label: "Cohorte active"
  filter :without_parent_text_message_since,
    as: :datepicker,
    required: false,
    label: "Parent sans SMS depuis"
  filter :registration_sources,
    as: :select,
    collection: proc { child_registration_source_select_collection },
    input_html: {multiple: true, data: {select2: {}}}
  filter :registration_sources_details,
    as: :select,
    collection: proc { child_registration_source_details_suggestions },
    input_html: {multiple: true, data: {select2: {}}}
  filter :should_be_read,
    input_html: {data: {select2: {width: "100%"}}}
  filter :book_not_received
  filter :is_bilingual
  filter :second_language
  filter :postal_code,
    as: :string
  filter :supporter,
    input_html: {data: {select2: {}}}
  (1..5).each do |call_idx|
    filter "call#{call_idx}_status"
    filter "call#{call_idx}_duration"
    filter "call#{call_idx}_parent_progress_present",
      as: :boolean,
      label: "Note appel #{call_idx} présente"
    filter "call#{call_idx}_parent_progress",
      as: :select,
      collection: proc { child_support_call_parent_progress_select_collection },
      input_html: {multiple: true, data: {select2: {}}}
    filter "call#{call_idx}_language_awareness",
      as: :select,
      collection: proc { child_support_call_language_awareness_select_collection },
      input_html: {multiple: true, data: {select2: {}}}
    filter "call#{call_idx}_sendings_benefits",
      as: :select,
      collection: proc { child_support_call_sendings_benefits_select_collection },
      input_html: {multiple: true, data: {select2: {}}}
    if call_idx == 1
      filter :books_quantity,
             as: :select,
             collection: proc { child_support_books_quantity },
             input_html: {multiple: true, data: {select2: {}}}
    end
    filter "call#{call_idx}_reading_frequency",
      as: :select,
      collection: proc { child_support_call_reading_frequency_select_collection },
      input_html: {multiple: true, data: {select2: {}}}
  end
  filter :created_at
  filter :updated_at

  batch_action :assign_supporter, form: -> {
    {
      I18n.t("activerecord.attributes.child_support.supporter") => AdminUser.pluck(:name, :id)
    }
  } do |ids, inputs|
    batch_action_collection.find(ids).each do |child_support|
      supporter_id = inputs[I18n.t("activerecord.attributes.child_support.supporter")]
      child_support.supporter_id = supporter_id
      child_support.save!
    end
    redirect_to request.referer, notice: "Responsable mis à jour"
  end

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form(remote: true) do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs do
      columns do
        column do
          f.input :supporter,
            input_html: {data: {select2: {}}}
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
                render "parent",
                  parent: parent,
                  should_contact_parent: should_contact_parent
              end
            end
            column do
              # children
              f.object.children.each do |c|
                child = c.decorate

                render "child", child: child
              end
            end
          end
        end
        column do
          f.label :important_information
          f.input :important_information, label: false, input_html: {rows: 3, style: "width: 100%"}
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
          tags_input(f)
          f.input :to_call
        end
      end
      tabs do
        (1..5).each do |call_idx|
          tab "Appel #{call_idx}" do
            columns do
              column do
                f.input "call#{call_idx}_status", input_html: {style: "width: 70%"}
                f.input "call#{call_idx}_duration", input_html: {style: "width: 70%"}
              end
              column do
                f.input "call#{call_idx}_status_details", input_html: {rows: 5, style: "width: 70%"}
              end
            end

            columns do
              column do
                f.input "call#{call_idx}_technical_information",
                  input_html: {
                    rows: 8,
                    style: "width: 70%",
                    value: f.object.send("call#{call_idx}_technical_information").presence ||
                      I18n.t("child_support.default.call_technical_information")

                  }
                f.input "call#{call_idx}_parent_actions",
                  input_html: {
                    rows: 8,
                    style: "width: 70%",
                    value: f.object.send("call#{call_idx}_parent_actions").presence ||
                      I18n.t("child_support.default.call_parent_actions")

                  }
                f.input "call#{call_idx}_language_awareness",
                  as: :radio,
                  collection: child_support_call_language_awareness_select_collection
                f.input "call#{call_idx}_parent_progress",
                  as: :radio,
                  collection: child_support_call_parent_progress_select_collection
                f.input "call#{call_idx}_reading_frequency",
                  as: :radio,
                  collection: child_support_call_reading_frequency_select_collection
                f.input "call#{call_idx}_sendings_benefits",
                  as: :radio,
                  collection: child_support_call_sendings_benefits_select_collection
                f.input "call#{call_idx}_sendings_benefits_details", input_html: {rows: 5, style: "width: 70%"}
              end
              column do
                f.input "call#{call_idx}_language_development", input_html: {rows: 8, style: "width: 70%"}
                f.input "call#{call_idx}_goals", input_html: {rows: 8, style: "width: 70%"}
                f.input "call#{call_idx}_notes",
                  input_html: {
                    rows: 8,
                    style: "width: 70%"
                  }
                if call_idx == 1
                  f.input :books_quantity, as: :radio, collection: child_support_books_quantity
                end
              end
            end
          end
        end
        if f.object.first_child
          %i[parent1 parent2].each do |k|
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
                collection: child_gender_select_collection
              first_child_f.input :should_contact_parent1
              first_child_f.input :should_contact_parent2
              first_child_f.input :registration_source,
                collection: child_registration_source_select_collection,
                input_html: {data: {select2: {}}}
              first_child_f.input :registration_source_details
            end
          end
          tab "Historique" do
            render "admin/events/history", events: f.object.parent_events.order(occurred_at: :desc).decorate
          end
        end
      end
    end
    f.actions
  end

  base_attributes = %i[
    important_information supporter_id should_be_read book_not_received is_bilingual second_language to_call books_quantity
  ] + [tags_params]
  parent_attributes = %i[
    id
    gender first_name last_name phone_number email letterbox_name address postal_code city_name
    is_ambassador is_lycamobile job
  ]
  first_child_attributes = [{
    first_child_attributes: [
      :id,
      :gender, :should_contact_parent1, :should_contact_parent2,
      :registration_source, :registration_source_details,
      {
        parent1_attributes: parent_attributes,
        parent2_attributes: parent_attributes
      }
    ]
  }]
  # block is mandatory here because ChildSupport.call_attributes hits DB
  permit_params do
    base_attributes + ChildSupport.call_attributes + first_child_attributes
  end

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    tabs do
      tab I18n.t("child_support.base") do
        attributes_table title: I18n.t("child_support.base") do
          row :supporter
          row :parent1 do |decorated|
            if decorated.model.parent1
              render "parent",
                parent: decorated.model.parent1.decorate,
                should_contact_parent: decorated.should_contact_parent1?
            end
          end
          row :parent2 do |decorated|
            if decorated.model.parent2
              render "parent",
                parent: decorated.model.parent2.decorate,
                should_contact_parent: decorated.should_contact_parent2?
            end
          end
          row :children
          row :to_call
          row :important_information
          row :book_not_received
          row :should_be_read
          row :is_bilingual
          row :second_language
          row :tags
          row :created_at
          row :updated_at
        end
      end
      (1..5).each do |call_idx|
        tab "Appel #{call_idx}" do
          attributes_table title: "Appel #{call_idx}" do
            row "call#{call_idx}_status"
            row "call#{call_idx}_status_details"
            row "call#{call_idx}_duration"
            row "call#{call_idx}_technical_information"
            row "call#{call_idx}_parent_actions"
            row "call#{call_idx}_language_awareness"
            row "call#{call_idx}_parent_progress"
            row "call#{call_idx}_sendings_benefits"
            row "call#{call_idx}_sendings_benefits_details"
            row "call#{call_idx}_language_development"
            if call_idx == 1
              row :books_quantity
            end
            row "call#{call_idx}_reading_frequency"
            row "call#{call_idx}_goals"
            row "call#{call_idx}_notes"
          end
        end
      end
      if resource.first_child
        tab "Historique" do
          render "admin/events/history", events: resource.parent_events.order(occurred_at: :desc).decorate
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

    (1..5).each do |call_idx|

      column "call#{call_idx}_status"
      column "call#{call_idx}_status_details"
      column "call#{call_idx}_duration"
      column("call#{call_idx}_technical_information") do |cs|
        cs.send("call#{call_idx}_technical_information_text")
      end
      column("call#{call_idx}_parent_actions") { |cs| cs.send("call#{call_idx}_parent_actions_text") }
      column "call#{call_idx}_language_awareness"
      column "call#{call_idx}_parent_progress"
      column "call#{call_idx}_sendings_benefits"
      column "call#{call_idx}_sendings_benefits_details"
      column("call#{call_idx}_language_development") { |cs| cs.send("call#{call_idx}_language_development_text") }
      if call_idx == 1
        column :books_quantity
      end
      column "call#{call_idx}_reading_frequency"
      column("call#{call_idx}_goals") { |cs| cs.send("call#{call_idx}_goals_text") }
      column("call#{call_idx}_notes") { |cs| cs.send("call#{call_idx}_notes_text") }

    end

    column :tag_list

    column :created_at
    column :updated_at
  end

  action_item :other_family_child_supports,
    only: %i[show edit],
    if: proc { resource.has_other_family_child_supports? } do
    dropdown_menu "Autres suivis" do
      resource.other_family_child_supports.each do |other_child_support|
        item other_child_support.decorate.dropdown_menu_item, url_for(id: other_child_support.id)
      end
    end
  end

  controller do
    after_action :add_tags_to_children_and_parents, only: %i[show update]

    def add_tags_to_children_and_parents
      child_support = ChildSupport.find(params[:id])
      child_support.children.each do |child|
        child.update! tag_list: child_support.tag_list
        child.parent1&.update! tag_list: (child.parent1&.tag_list + child_support.tag_list).uniq
        child.parent2&.update! tag_list: (child.parent2&.tag_list + child_support.tag_list).uniq
      end
    end
  end
end
