ActiveAdmin.register Media::TextMessage do

  menu parent: 'Médiathèque'

  decorate_with Media::TextMessageDecorator

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
    column :body do |decorated|
      decorated.truncated_body
    end
    column :image do |decorated|
      decorated.image_tag(max_height: '50px')
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
  filter :body

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
      row :body, class: 'row-pre'
      row :image do |decorated|
        decorated.image_tag(max_height: '50px')
      end
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
      f.input :body, as: :text, input_html: { rows: 10 }
      f.input :image, as: :file
    end
    f.actions
  end

  permit_params :folder_id, :name, :body, :image, tags_params

end
