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
               input_html: { multiple: true, data: { select2: {} } },
               label: 'Tags'

        batch_action :add_tags do |ids|
          session[:add_tags_ids] = ids
          redirect_to action: :add_tags
        end

        collection_action :add_tags do
          @klass = collection.object.klass
          @ids = session.delete(:add_tags_ids) || []
          @form_action = url_for(action: :perform_adding_tags)
          @back_url = request.referer
          render 'active_admin/tags/add_tags'
        end

        collection_action :perform_adding_tags, method: :post do
          ids = params[:ids]
          tags = params[:tag_list]
          back_url = params[:back_url]

          collection.object.klass.where(id: ids).each do |object|
            object.tag_list.add(tags)
            object.save(validate: false)
            if object.has_attribute? :parent1_id
              if object.parent1_id
                parent1 = Parent.find(object.parent1_id)
                parent1.update! tag_list: (parent1.tag_list + object.tag_list).uniq
              end
            end
            if object.has_attribute? :parent2_id
              if object.parent2_id
                parent2 = Parent.find(object.parent2_id)
                parent2.update! tag_list: (parent2.tag_list + object.tag_list).uniq
              end
            end
            if object.has_attribute? :child_support_id
              if object.child_support_id
                child_support = ChildSupport.find(object.child_support_id)
                child_support.update! tag_list (child_support.tag_list + object.tag_list).uniq
              end
            end
            if object.has_attribute? :children
              object.children.each do |child|
                child.update! tag_list (child.tag_list + object.tag_list).uniq
                child.parent1&.update! tag_list: (child.parent1&.tag_list + object.tag_list).uniq
                child.parent2&.update! tag_list: (child.parent2&.tag_list + object.tag_list).uniq
              end
            end
          end
          redirect_to back_url, notice: 'Tags ajoutés'
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
