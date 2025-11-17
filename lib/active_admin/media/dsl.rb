module ActiveAdmin
  module Media
    module DSL

      def register_text_messages_bundle_index(with_comments: false)
        index download_links: false do
          selectable_column
          id_column
          if with_comments
            column '', :comments do |decorated|
              decorated.comments_indicator
            end
          end
          column :name
          # column :theme
          column :tags do |model|
            model.tags(context: 'tags')
          end
          (1..3).each do |msg_idx|
            column "body#{msg_idx}".to_sym do |decorated|
              decorated.send("truncated_body#{msg_idx}")
            end
            column "image#{msg_idx}".to_sym, sortable: "image#{msg_idx}_id" do |decorated|
              decorated.send("image#{msg_idx}_admin_link_with_image", max_height: '50px')
            end
            # column "link#{msg_idx}".to_sym, sortable: "link#{msg_idx}_id" do |decorated|
            #   decorated.send("link#{msg_idx}_admin_link")
            # end
          end
          column :created_at do |decorated|
            decorated.created_at_date
          end
          actions dropdown: true do |decorated|
            discard_links_args(decorated.model).each do |args|
              item *args
            end
          end
        end

        filter :name
        # filter :theme,
        #        as: :select,
        #        collection: proc { medium_theme_suggestions },
        #        input_html: { multiple: true, data: { select2: {} } }
        filter :body1
        filter :body2
        filter :body3

        filter :occurred_at
        filter :created_at
      end

      def register_text_messages_bundle_show(with_comments: false)
        show do
          attributes_table do
            send (with_comments ? :row_with_comments : :row), :folder_id do |decorated|
              decorated.folder_link
            end
            send (with_comments ? :row_with_comments : :row), :name
            # send (with_comments ? :row_with_comments : :row), :theme
            send (with_comments ? :row_with_comments : :row), :tag_list do |decorated|
              decorated.tags
            end
            row :created_at
            row :discarded_at
          end

          columns do
            (1..3).each do |msg_idx|
              column do
                attributes_table title: "Message #{msg_idx}" do
                  send (with_comments ? :row_with_comments : :row), "body#{msg_idx}", class: 'row-pre'
                  send (with_comments ? :row_with_comments : :row), "image#{msg_idx}_id" do |decorated|
                    decorated.send("image#{msg_idx}_admin_link_with_image", max_width: '100px')
                  end
                  send (with_comments ? :row_with_comments : :row), "link#{msg_idx}_id" do |decorated|
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
            f.input :folder,
                    collection: medium_folder_select_collection,
                    prompt: 'Aucun (dossier racine)',
                    input_html: { data: { select2: {} } }
            f.input :name
            # f.input :theme,
            #         as: :datalist,
            #         collection: medium_theme_suggestions
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
                          include_blank: 'Aucune',
                          input_html: { data: { select2: {} } }
                  f.input "link#{idx}",
                          collection: redirection_target_medium_select_collection,
                          include_blank: 'Aucun',
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

      def register_comments
        # add 'Quick add field_comment' action
        member_action :quick_field_comment, method: :post do
          field_comment = FieldComment.new(
            author: current_admin_user,
            related: resource,
            field: params[:field],
            content: params[:content]
          )
          if field_comment.save
            render plain: 'OK'
          else
            render json: field_comment.errors, status: :unprocessable_entity
          end
        end

        # skip forery protection for quick adding field_comment
        controller do
          skip_forgery_protection only: :quick_field_comment
        end
      end

    end
  end
end

# dirty hack

module ActiveAdmin::AttributesTableFieldComments
  def row_with_comments(*args, &block)
    row(*args, &block)
    @table.children.last.children.last << field_comments_for(args[0])
  end
end

::ActiveAdmin::Views::AttributesTable.send :include, ActiveAdmin::AttributesTableFieldComments
