ActiveAdmin.register Events::TextMessage, as: 'Sent By App TextMessage' do

  menu parent: 'Événements', label: 'SMS envoyé'

  decorate_with Events::TextMessageDecorator

  has_better_csv
  use_discard

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  includes :related

  index do
    selectable_column
    id_column
    column :related do |decorated|
      decorated.related_link
    end
    column :related_current_child do |decorated|
      decorated.related_current_child_link
    end
    column :spot_hit_status do |decorated|
      decorated.spot_hit_status_value
    end
    column :related_current_child_group
    column :occurred_at
    column :body do |decorated|
      decorated.truncated_body
    end
    column :created_at do |decorated|
      l decorated.created_at.to_date, format: :default
    end
    actions dropdown: true do |decorated|
      discard_links_args(decorated.model).each do |args|
        item *args
      end
    end
  end

  filter :parent_current_child_group_id_in,
         as: :select,
         collection: proc { child_group_select_collection },
         input_html: { multiple: true, data: { select2: {} } },
         label: 'Cohorte'

  filter :parent_current_child_supporter_id_in,
         as: :select,
         collection: proc { child_support_supporter_select_collection },
         input_html: { multiple: true, data: { select2: {} } },
         label: 'Accompagnante'

  filter :body
  filter :message_provider, as: :select, collection: proc { Events::TextMessage::PROVIDERS }, input_html: { multiple: true, data: { select2: {} } }, label: 'Envoyé via'

  filter :occurred_at
  filter :created_at

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :related do |model|
        model.related_link
      end
      row :related_current_child do |model|
        model.related_current_child_link
      end
      row :spot_hit_status do |decorated|
        decorated.spot_hit_status_value
      end
      row :occurred_at
      row :body, class: 'row-pre'
      row :created_at
      row :discarded_at
    end
  end

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  controller do
    def build_new_resource
      resource = super
      resource.occurred_at = Time.zone.now
      resource
    end

    def scoped_collection
      end_of_association_chain.sent_by_app_text_messages
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      if f.object.related
        li class: :input do
          label f.object.class.human_attribute_name('related'), class: :label
          div style: "padding-top: 6px" do
            f.object.decorate.related_link
          end
        end
      end

      f.input :related_type, as: :hidden
      f.input :related_id, as: :hidden

      f.input :occurred_at

      f.input :body, input_html: { rows: 10 }
    end
    f.actions
  end

  permit_params :related_type, :related_id, :occurred_at, :body

  # ---------------------------------------------------------------------------
  # CSV EXPORT
  # ---------------------------------------------------------------------------

  csv do
    column :id

    column :related_id
    column :related_name

    column :related_current_child_id
    column :related_current_child_name

    column :related_current_child_group_name
    column :related_current_child_group_status

    column :occurred_at
    column :body

    column :created_at
    column :updated_at
    column :discarded_at
  end

end
