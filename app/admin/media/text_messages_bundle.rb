ActiveAdmin.register Media::TextMessagesBundle do

  menu parent: 'Médiathèque', label: 'Trios SMS'

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
    column :theme
    column :tags
    column :body1 do |decorated|
      decorated.truncated_body1
    end
    column :image1 do |decorated|
      decorated.image1_tag(max_height: '50px')
    end
    column :link1 do |decorated|
      decorated.link1_tag
    end
    column :body2 do |decorated|
      decorated.truncated_body2
    end
    column :image2 do |decorated|
      decorated.image2_tag(max_height: '50px')
    end
    column :link2 do |decorated|
      decorated.link2_tag
    end
    column :body3 do |decorated|
      decorated.truncated_body3
    end
    column :image3 do |decorated|
      decorated.image3_tag(max_height: '50px')
    end
    column :link3 do |decorated|
      decorated.link3_tag
    end
    column :created_at do |decorated|
      decorated.created_at_date
    end
    actions do |decorated|
      discard_links(decorated.model, class: 'member_link')
    end
  end

  filter :name
  filter :theme,
         as: :select,
         collection: proc { medium_theme_suggestions },
         input_html: { multiple: true, data: { select2: {} } }
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
      row :theme
      row :tags
      row :created_at
      row :discarded_at
    end

    columns do
      (1..3).each do |idx|
        column do
          attributes_table title: "Message #{idx}" do
            row "body#{idx}", class: 'row-pre'
            row "image#{idx}" do |decorated|
              decorated.send("image#{idx}_tag", max_height: '50px')
            end
            row "link#{idx}" do |decorated|
              decorated.send("link#{idx}_tag")
            end
          end
        end
      end
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
      f.input :theme,
              as: :datalist,
              collection: medium_theme_suggestions
      tags_input(f)
      columns do
        (1..3).each do |idx|
          column do
            h3 "Message #{idx}"
            f.input "body#{idx}",
                    as: :text,
                    label: false,
                    input_html: {
                      rows: 10,
                      style: 'width: 100%',
                      data: {
                        'chars-counter': 152
                      }
                    }
            f.input "image#{idx}",
                    collection: media_image_select_collection,
                    input_html: { data: { select2: {} } }
            f.input "link#{idx}",
                    collection: redirection_target_medium_select_collection,
                    input_html: { data: { select2: {} } }
          end
        end
      end
    end
    f.actions
  end

  permit_params :folder_id, :name, :theme,
                :body1, :body2, :body3,
                :image1_id, :image2_id, :image3_id,
                :link1_id, :link2_id, :link3_id,
                tags_params

end
