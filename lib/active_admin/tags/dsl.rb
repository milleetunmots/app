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
      end

      def tags_params
        return {
          tag_list: []
        }
      end

    end
  end
end
