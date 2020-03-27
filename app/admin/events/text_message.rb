ActiveAdmin.register Events::TextMessage do

  menu parent: 'Événements'

  decorate_with Events::TextMessageDecorator

  has_better_csv

  actions :all, except: [:destroy]

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  includes :related

  index do
    selectable_column
    id_column
    column :related do |model|
      model.related_link
    end
    column :related_first_child do |model|
      model.related_first_child_link
    end
    column :related_first_child_group
    column :occurred_at
    column :body
    column :created_at do |model|
      l model.created_at.to_date, format: :default
    end
    actions do |model|
      if model.discarded?
        (
          link_to 'Restaurer', [:undiscard, :admin, model], method: :put, class: 'member_link green'
        ) + (
          link_to 'Supprimer définitivement', [:really_destroy, :admin, model], method: :delete, class: 'member_link red', data: { confirm: I18n.t('active_admin.delete_confirmation') }
        )
      else
        link_to 'Supprimer', [:discard, :admin, model], method: :put, class: 'member_link red'
      end
    end
  end

  scope :kept, default: true
  scope :discarded

  filter :parent_first_child_group_id_in,
         as: :select,
         collection: proc { Group.order(:name) },
         input_html: { multiple: true, data: { select2: {} } },
         label: 'Cohorte'

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
      row :related_first_child do |model|
        model.related_first_child_link
      end
      row :occurred_at
      row :body
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
      resource.occurred_at = Time.now
      resource
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      if f.object.related
        li class: :input do
          label I18n.t('activerecord.attributes.events/text_message.related'), class: :label
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

    column :related_first_child_id
    column :related_first_child_name

    column :related_first_child_group_name
    column :related_first_child_has_quit_group

    column :occurred_at
    column :body

    column :created_at
    column :updated_at
    column :discarded_at
  end

  # ---------------------------------------------------------------------------
  # DISCARD
  # ---------------------------------------------------------------------------

  member_action :discard, method: :put do
    resource.discard!
    redirect_to request.referer, notice: 'Mis à la corbeille'
  end

  member_action :undiscard, method: :put do
    resource.undiscard!
    redirect_to request.referer, notice: 'Sorti de la corbeille'
  end

  member_action :really_destroy, method: :delete do
    resource.destroy
    redirect_to admin_events_text_messages_path(scope: :discarded), notice: 'Supprimé'
  end

  action_item :discard_undiscard, only: :show do
    if resource.discarded?
      (
        link_to 'Restaurer', [:undiscard, :admin, resource], method: :put, class: :green
      ) + ' ' + (
        link_to 'Supprimer définitivement', [:really_destroy, :admin, resource], method: :delete, class: :red, data: { confirm: I18n.t(:delete_confirmation) }
      )
    else
      link_to 'Supprimer', [:discard, :admin, resource], method: :put, class: :red
    end
  end

end
