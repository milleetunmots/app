module ActiveAdmin
  module PaperTrail
    module DSL

      # Call this inside your resource definition to add the needed member actions
      # for your sortable resource.
      #
      # Example:
      #
      # #app/admin/players.rb
      #
      # ActiveAdmin.register Player do
      #   # Sort players by position
      #   config.sort_order = 'position'
      #
      #   # Add member actions for versioning.
      #   has_paper_trail
      # end
      def has_paper_trail

        # add versions timeline sidebar on show page
        sidebar I18n.t('active_admin.paper_trail.sidebar.title'), partial: 'layouts/version', only: :show

        controller do
          # build a @versions variable for the sidebar
          # also, replace resource with an old version when clicked inside the sidebar
          def find_resource
            puts "FIND RESOURCE"
            resource = super
            @versions = resource.versions
            resource = resource.versions[params[:version].to_i].reify if params[:version]
            resource
          end
        end
      end

    end
  end
end
