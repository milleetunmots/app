class Group

  class GetScheduledJobsService

    require 'sidekiq/api'
    attr_reader :scheduled_jobs

    GROUP_JOB_CLASS_NAMES = {
      'ChildrenSupportModule::ProgramFirstSupportModuleJob' => 'Programmation du 1er module',
      'ChildrenSupportModule::FillParentsAvailableSupportModulesJob' => 'Ajout des choix du module suivant sur les fiches de suivi',
      'ChildrenSupportModule::VerifyAvailableModulesTaskJob' => 'Vérification que tous les enfants ont des choix disponibles',
      'ChildrenSupportModule::CreateChildrenSupportModuleJob' => 'Préparation préalable au choix des parents',
      'ChildrenSupportModule::SelectDefaultSupportModuleJob' => 'Assignation des modules par défaut',
      'ChildrenSupportModule::VerifyChosenModulesTaskJob' => 'Détection des modules sans choix',
      'ChildrenSupportModule::CheckCreditsForGroupJob' => 'Vérification du nombre suffisant de crédits pour la programmation des modules',
      'ChildrenSupportModule::SelectModuleJob' => 'Programmation des SMS de choix du module',
      'ChildrenSupportModule::ProgramSupportModuleSmsJob' => 'Programmation des SMS en fonction du module choisi'
    }.freeze

    def initialize(group_id)
      @group_id = group_id
      @scheduled_jobs = []
    end

    def call
      jobs = Sidekiq::ScheduledSet.new
      jobs.each do |job|
        next unless job.args.any?

        job_class_name = job.args[0]['job_class']
        job_group_id = job.args[0]['arguments']&.first
        job_scheduled_date = job.at
        if GROUP_JOB_CLASS_NAMES.key?(job_class_name) && job_group_id == @group_id.to_i
          @scheduled_jobs << { name: GROUP_JOB_CLASS_NAMES[job_class_name], scheduled_date: job_scheduled_date }
        end
      end

      @scheduled_jobs.sort_by! { |hash| hash[:scheduled_date] }

      self
    end
  end
end
