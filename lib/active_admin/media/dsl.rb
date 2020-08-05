module ActiveAdmin
  module Media
    module DSL

      def register_text_messages_bundle_index
        index do
          selectable_column
          id_column
          column :name
          column :theme
          column :tags
          (1..3).each do |msg_idx|
            column "body#{msg_idx}" do |decorated|
              decorated.send("truncated_body#{msg_idx}")
            end
            column "image#{msg_idx}", sortable: "image#{msg_idx}_id" do |decorated|
              decorated.send("image#{msg_idx}_admin_link_with_image", max_height: '50px')
            end
            column "link#{msg_idx}", sortable: "link#{msg_idx}_id" do |decorated|
              decorated.send("link#{msg_idx}_admin_link")
            end
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
      end

      def register_text_messages_bundle_show
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
            (1..3).each do |msg_idx|
              column do
                attributes_table title: "Message #{msg_idx}" do
                  row "body#{msg_idx}", class: 'row-pre'
                  row "image#{msg_idx}" do |decorated|
                    decorated.send("image#{msg_idx}_admin_link_with_image", max_width: '100px')
                  end
                  row "link#{msg_idx}" do |decorated|
                    decorated.send("link#{msg_idx}_admin_link")
                  end
                end
              end
            end
          end
        end
      end

      def register_text_messages_bundle_form
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

    end
  end
end
