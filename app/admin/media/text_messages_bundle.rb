ActiveAdmin.register Media::TextMessagesBundle do

  menu parent: 'Médiathèque'

  decorate_with Media::TextMessagesBundleDecorator

  has_better_csv
  has_paper_trail
  has_tags
  use_discard

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    selectable_column
    id_column
    column :name
    column :tags
    column :body1 do |decorated|
      decorated.truncated_body1
    end
    column :body2 do |decorated|
      decorated.truncated_body2
    end
    column :body3 do |decorated|
      decorated.truncated_body3
    end
    column :created_at do |decorated|
      decorated.created_at_date
    end
    column :updated_at do |decorated|
      decorated.updated_at_date
    end
    actions do |decorated|
      discard_links(decorated.model, class: 'member_link')
    end
  end

  filter :name
  filter :body1
  filter :body2
  filter :body3

  filter :occurred_at
  filter :created_at

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :folder
      row :name
      row :tags
      row :body1, class: 'row-pre'
      row :body2, class: 'row-pre'
      row :body3, class: 'row-pre'
      row :created_at
      row :discarded_at
    end
  end

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :folder
      f.input :name
      tags_input(f)
      f.input :body1, as: :text, input_html: { rows: 10 }
      f.input :body2, as: :text, input_html: { rows: 10 }
      f.input :body3, as: :text, input_html: { rows: 10 }
    end
    f.actions
  end

  permit_params :folder_id, :name, :body1, :body2, :body3, tags_params

end
