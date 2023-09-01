class Group

  class GetScheduledJobsService

    require 'sidekiq/api'
    attr_reader :scheduled_jobs

    GROUP_JOB_CLASS_NAMES = {
      'ChildrenSupportModule::ProgramFirstSupportModuleJob' => 'Programmation du 1er module',
      'ChildrenSupportModule::FillParentsAvailableSupportModulesJob' => 'Ajout des modules disponibles sur les fiches de suivi',
      'ChildrenSupportModule::VerifyAvailableModulesTaskJob' => 'Vérification que tous les enfants ont des modules disponibles sur leur fiche de suivi',
      'ChildrenSupportModule::CreateChildrenSupportModuleJob' => 'Préparation préalable au choix des parents',
      'ChildrenSupportModule::SelectDefaultSupportModuleJob' => 'Assignation des modules par défaut',
      'ChildrenSupportModule::VerifyChosenModulesTaskJob' => 'Détection des modules sans choix',
      'ChildrenSupportModule::CheckCreditsForGroupJob' => 'Vérification du nombre suffisant de crédits pour la programmation des modules',
      'ChildrenSupportModule::SelectModuleJob' => 'Programmation des SMS de choix du module',
      'ChildrenSupportModule::ProgramSupportModuleSmsJob' => 'Programmation des SMS du module choisi'
    }.freeze

    def initialize(group_id)
      @group_id = group_id
      @scheduled_jobs = []
    end

    def call
      jobs = Sidekiq::ScheduledSet.new
      jobs.each do |job|
        next unless job.args.any?

        add_scheduled_job(job)
      end
      @scheduled_jobs.sort_by! { |hash| hash[:scheduled_date] }

      self
    end

    private

    def add_scheduled_job(job)
      job_class_name = job.args[0]['job_class']
      job_group_id = job.args[0]['arguments']&.first
      job_scheduled_date = job.at
      return unless GROUP_JOB_CLASS_NAMES.key?(job_class_name) && job_group_id == @group_id.to_i

      name = if job_class_name == ChildrenSupportModule::SelectModuleJob.to_s && job.args[0]['arguments']&.third.eql?(true)
               "Programmation des SMS de choix du module aux parents n'ayant pas reçu d'appel 2"
             else
               GROUP_JOB_CLASS_NAMES[job_class_name]
             end
      @scheduled_jobs << { name: name, scheduled_date: job_scheduled_date }
    end
  end
end
