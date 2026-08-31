ActiveAdmin.register AllowedPattern do

  menu parent: 'Gestion des envois', label: 'Patterns autorisés', priority: 2

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    selectable_column
    id_column
    column :kind do |allowed_pattern|
      AllowedPattern.human_attribute_name("kind.#{allowed_pattern.kind}")
    end
    column :match_type do |allowed_pattern|
      AllowedPattern.human_attribute_name("match_type.#{allowed_pattern.match_type}")
    end
    column :value
    column :created_at
    actions
  end

  filter :kind, as: :select, collection: proc { allowed_pattern_kind_select_collection }
  filter :match_type
  filter :value
  filter :created_at

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.semantic_errors(*f.object.errors.details.keys)
    f.inputs do
      f.input :kind, as: :select, collection: allowed_pattern_kind_select_collection, include_blank: false
      f.input :match_type,
              as: :select,
              collection: allowed_pattern_match_type_select_collection,
              include_blank: false
      f.input :value, hint: "URL : un domaine (monpartenaire.fr) ou une URL complète (https://exemple.fr/page) selon le type de correspondance. Numéro de téléphone : le numéro autorisé, dans n'importe quelle notation (0810123456, +33 810 12 34 56)."
    end
    f.actions
  end

  permit_params :kind, :match_type, :value

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :kind do |allowed_pattern|
        AllowedPattern.human_attribute_name("kind.#{allowed_pattern.kind}")
      end
      row :match_type do |allowed_pattern|
        AllowedPattern.human_attribute_name("match_type.#{allowed_pattern.match_type}")
      end
      row :value
      row :created_at
      row :updated_at
    end
  end

  # ---------------------------------------------------------------------------
  # controller
  # ---------------------------------------------------------------------------

  controller do
    def destroy
      requested_object = resource
      if requested_object.destroy
        redirect_to admin_allowed_patterns_path, notice: 'Le pattern autorisé a été supprimé.'
      else
        redirect_to admin_allowed_patterns_path, alert: requested_object.errors.full_messages.to_sentence
      end
    end
  end
end
