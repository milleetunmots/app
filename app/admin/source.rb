ActiveAdmin.register Source do

  menu priority: 1, parent: 'Source'

  decorate_with SourceDecorator

  actions :all, except: [:destroy]

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index row_class: ->(source) { "archived-row" if source.is_archived? }, download_links: false do
    selectable_column
    id_column
    column :name
    column :channel
    column :department
    column :utm
    column :comment
    column :children
    column :is_archived
    actions defaults: true do |source|
      if source.is_archived?
        link_to "Désarchiver", unarchive_admin_source_path(source), method: :put, class: "member_link"
      else
        link_to "Archiver", archive_admin_source_path(source), method: :put, class: "member_link"
      end
    end
  end

  filter :name
  filter :channel,
        as: :select,
        collection: proc { source_channel_select_collection },
        input_html: { multiple: true, data: { select2: {} } }
  filter :department
  filter :utm
  filter :is_archived
  filter :created_at
  filter :updated_at

  # ---------------------------------------------------------------------------
  # scopes
  # ---------------------------------------------------------------------------

  scope :all, group: :all, default: true
  scope :by_bao, group: :canal
  scope :by_caf, group: :canal
  scope :by_local_partner, group: :canal
  scope :by_pmi, group: :canal
  scope(I18n.t('activerecord.attributes.source.is_archived')) do |scope|
    scope.merge(Source.archived)
  end

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs do
      f.input :name
      f.input :channel, collection: source_channel_select_collection
      f.input :department
      f.input :utm, hint: "Identifiant unique envoyé dans le lien d'inscription pour détecter la source. Utilisé pour sélectionner automatiquement les cafs par exemple"
      f.input :is_archived
      f.input :comment
    end
    f.actions
  end

  permit_params :name, :channel, :department, :comment, :utm, :is_archived

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :name
      row :channel
      row :department
      row :utm
      row :is_archived
      row :comment
      row :children
      row :created_at
      row :updated_at
    end
  end

  action_item :archive, only: :show, if: proc { !resource.is_archived? } do
    link_to 'Archiver', [:archive, :admin, resource], method: :put
  end

  action_item :unarchive, only: :show, if: proc { resource.is_archived? } do
    link_to 'Désarchiver', [:unarchive, :admin, resource], method: :put
  end

  member_action :archive, method: :put do
    resource.archive!
    redirect_to [:admin, resource], notice: "La source a été archivée."
  end

  member_action :unarchive, method: :put do
    resource.unarchive!
    redirect_to [:admin, resource], notice: "La source a été désarchivée."
  end
end
