module ActiveAdmin
  module Tasks
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
      #   # Add member actions for tasking
      #   has_tasks
      # end
      def has_tasks

        # add TODO sidebar on show page
        sidebar I18n.t('active_admin.tasks.sidebar.title'),
                partial: 'layouts/active_admin/tasks/sidebar',
                only: :show

        action_item :task, only: :edit do
          link_to I18n.t('active_admin.tasks.sidebar.add_link'),
                  url_for_new_task(resource.decorate),
                  target: '_blank'
        end

      end

    end
  end
end
