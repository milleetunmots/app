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
      def has_tasks(with_quick_task = true)

        # add TODO sidebar on show page
        sidebar I18n.t('active_admin.tasks.sidebar.title'),
                partial: 'layouts/active_admin/tasks/sidebar',
                only: :show

        # add 'Add task' button on edit page
        action_item :task, only: :edit do
          link_to I18n.t('active_admin.tasks.sidebar.add_link'),
                  url_for_new_task(resource.decorate),
                  target: '_blank'
        end

        # add 'Quick add task' action
        member_action :quick_task, method: :post do
          task = Task.new(
            related: resource,
            title: params[:title]
          )
          if task.save
            render plain: 'OK'
          else
            render json: task.errors, status: :unprocessable_entity
          end
        end

        # skip forery protection for quick adding task
        controller do
          skip_forgery_protection only: :quick_task
        end

        # add 'Quick add task' button on edit page
        if with_quick_task
          action_item :task, only: :edit do
            link_to I18n.t('active_admin.tasks.quick.link'),
                    { action: :quick_task },
                    target: '_blank',
                    class: 'quick-task-btn',
                    data: {
                      prompt: I18n.t('active_admin.tasks.quick.prompt'),
                      success: I18n.t('active_admin.tasks.quick.success'),
                      error: I18n.t('active_admin.tasks.quick.error')
                    }
          end
        end
      end

    end
  end
end
