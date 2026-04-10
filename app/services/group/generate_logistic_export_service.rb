class Group

  class GenerateLogisticExportService

    require 'sidekiq/api'

    attr_reader :errors

    def initialize
      @errors = []
    end

    def call
      chosen_modules_groups = []
      missing_chosen_modules_groups = []

      Group.kept.with_calls.excluded_from_analytics.where(id: group_ids_from_scheduled_sms_jobs).find_each do |group|
        @group = group
        (missing_chosen_modules? ? missing_chosen_modules_groups : chosen_modules_groups) << @group
      end

      if missing_chosen_modules_groups.any?
        create_task_for_logistic_team(chosen_modules_groups, missing_chosen_modules_groups)
        @errors << "Cohortes avec des modules sans choix : #{missing_chosen_modules_groups.map(&:name).join(', ')}"
      end

      if chosen_modules_groups.any?
        export_service = Child::ExportBooksV2Service.new(group_ids: chosen_modules_groups.map(&:id)).call
        @errors.concat(export_service.errors) if export_service.errors.any?
      end

      self
    end

    private

    def next_module_index
      @group.support_module_programmed + 1
    end

    def group_ids_from_scheduled_sms_jobs
      from_time = Time.current
      to_time = 1.week.from_now

      Sidekiq::ScheduledSet.new.each_with_object([]) do |job, group_ids|
        next unless job.at.between?(from_time, to_time)
        next unless job.args.first.is_a?(Hash)
        next unless job.args.first['job_class'] == 'ChildrenSupportModule::ProgramSupportModuleSmsJob'

        group_id = job.args.first['arguments']&.first
        group_ids << group_id if group_id
      end.uniq
    end

    def missing_chosen_modules?
      ChildrenSupportModule.exists?(
        support_module: nil,
        module_index: next_module_index,
        child_id: @group.children.where(group_status: 'active').ids
      )
    end

    def create_task_for_logistic_team(complete_groups, incomplete_groups)
      title = 'Choix de modules incomplets — export YLS logistique bloqué'
      without_choice_lines = incomplete_groups.map do |group|
        ActionController::Base.helpers.link_to(
          group.name,
          Rails.application.routes.url_helpers.admin_children_support_modules_url(
            scope: 'without_choice', q: { group_id_in: [group.id], module_index_equals: group.support_module_programmed + 1 }
          ), target: '_blank', class: 'blue'
        )
      end

      with_choice_lines = complete_groups.map(&:name)

      description = +'<strong>Cohortes sans choix :</strong><br>'
      description << (without_choice_lines.any? ? without_choice_lines.join('<br>') : '—')
      description << '<br><br><strong>Cohortes avec choix :</strong><br>'
      description << (with_choice_lines.any? ? with_choice_lines.join('<br>') : '—')

      Task::CreateAutomaticTaskService.new(
        title: title,
        description: description
      ).call
    end
  end
end
