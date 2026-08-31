ActiveAdmin.register BlockedPattern do

  menu parent: 'Gestion des envois', label: 'Patterns interdits', priority: 3

  permit_params :kind, :value

  index do
    selectable_column
    id_column
    column :kind do |blocked_pattern|
      BlockedPattern.human_attribute_name("kind.#{blocked_pattern.kind}")
    end
    column :value
    column :normalized_value
    column :created_at
    actions
  end

  filter :kind, as: :select, collection: -> { BlockedPattern::KINDS.map { |kind| [BlockedPattern.human_attribute_name("kind.#{kind}"), kind] } }
  filter :value
  filter :created_at

  form do |f|
    f.semantic_errors(*f.object.errors.details.keys)
    f.inputs do
      f.input :kind, as: :select, collection: BlockedPattern::KINDS.map { |kind| [BlockedPattern.human_attribute_name("kind.#{kind}"), kind] }, include_blank: false
      f.input :value, hint: 'Mot-clé : mot ou expression, le matching ignore casse et accents, sur frontières de mots.'
    end
    f.actions
  end

  show do
    attributes_table do
      row :kind do |blocked_pattern|
        BlockedPattern.human_attribute_name("kind.#{blocked_pattern.kind}")
      end
      row :value
      row :normalized_value
      row :created_at
      row :updated_at
    end
  end
end
