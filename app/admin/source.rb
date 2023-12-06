ActiveAdmin.register Source do

  decorate_with SourceDecorator

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    selectable_column
    id_column
    column :name
    column :channel
    column :department
    column :utm
    column :comment
    actions
  end

  filter :name
  filter :channel,
        as: :select,
        collection: proc { source_channel_select_collection },
        input_html: { multiple: true, data: { select2: {} } }
  filter :department
  filter :utm
  filter :created_at
  filter :updated_at

  # ---------------------------------------------------------------------------
  # scopes
  # ---------------------------------------------------------------------------

  scope :all, group: :all
  scope :by_bao, group: :canal
  scope :by_caf, group: :canal
  scope :by_local_partner, group: :canal
  scope :by_pmi, group: :canal

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
      f.input :comment
    end
    f.actions
  end

  permit_params :name, :channel, :department, :comment, :utm

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :name
      row :channel
      row :department
      row :utm
      row :comment
      row :created_at
      row :updated_at
    end
  end
end
