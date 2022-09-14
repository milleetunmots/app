module ActiveAdmin
  module Tags
    module DSL

      # Call this inside your resource definition to add the needed member actions
      # for your sortable resource.
      #
      # Example:
      #
      # #app/admin/players.rb
      #
      # ActiveAdmin.register Player do
      #   # Add tags
      #   has_tags
      # end
      def has_tags
        filter :tagged_with_all,
          as: :select,
          collection: proc { tag_name_collection },
          input_html: {multiple: true, data: {select2: {}}},
          label: "Tags"

        batch_action :add_tags do |ids|
          session[:add_tags_ids] = ids
          redirect_to action: :add_tags
        end

        collection_action :add_tags do
          @klass = collection.object.klass
          @ids = session.delete(:add_tags_ids) || []
          @form_action = url_for(action: :perform_adding_tags)
          @back_url = request.referer
          render "active_admin/tags/add_tags"
        end

        collection_action :perform_adding_tags, method: :post do
          ids = params[:ids]
          tags = params[:tag_list]
          back_url = params[:back_url]

          collection.object.klass.where(id: ids).each do |object|
            object.tag_list.add(tags)
            object.save(validate: false)
          end
          redirect_to back_url, notice: "Tags ajoutés"
        end
      end

      def tags_params
        return {
          tag_list: []
        }
      end
    end
  end
end
