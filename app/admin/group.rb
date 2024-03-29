ActiveAdmin.register Group do
  decorate_with GroupDecorator

  has_better_csv
  has_paper_trail
  has_tasks
  use_discard

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    selectable_column
    id_column
    column :name
    column :children
    column :started_at
    column :ended_at
    column :support_modules_count
    column :is_programmed
    column :support_module_programmed
    column :expected_children_number
    column :created_at do |model|
      l model.created_at.to_date, format: :default
    end
    column :updated_at do |model|
      l model.updated_at.to_date, format: :default
    end
    actions dropdown: true do |decorated|
      discard_links_args(decorated.model).each do |args|
        item(*args)
      end
    end
  end

  filter :name
  filter :started_at
  filter :ended_at
  filter :support_modules_count
  filter :is_programmed
  filter :expected_children_number
  filter :created_at
  filter :updated_at

  scope :all, default: true
  scope :not_ended
  scope :ended

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.semantic_errors(*f.object.errors.keys)
    f.inputs do
      f.input :name
      f.input :started_at, as: :datepicker
      f.input :ended_at, as: :datepicker
      f.input :support_modules_count
      f.input :expected_children_number, hint: "Il n'y aura plus d'assignation automatique d'enfant à l'inscription une fois ce nombre atteint."
    end
    f.actions
  end

  permit_params :name, :started_at, :ended_at, :support_modules_count, :expected_children_number

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    tabs do
      tab I18n.t('group.base') do
        attributes_table do
          row :name
          row :children
          row :started_at
          row :ended_at
          row :support_modules_count
          row :support_module_programmed
          row :expected_children_number
          row :is_programmed
        end
      end
      tab I18n.t('group.supporters') do
        panel I18n.t('group.panel_supporters_title') do
          table_for resource.supporters.distinct.order(:name) do
            column I18n.t('group.supporter_name') do |supporter|
              link_to supporter.name, [:admin, supporter]
            end
            column I18n.t('group.supporter_child_supports_count') do |supporter|
              link_to supporter.child_supports.joins(:children).where(children: { group_id: resource.id }).uniq.size,
                      [:admin, :child_supports, { q: { group_id_in: [resource.id], supporter_id_in: [supporter.id] } }]
            end
            column I18n.t('group.supporter_children_count') do |supporter|
              link_to supporter.children.where(group_id: resource.id).size, [:admin, :children, { q: { group_id_in: [resource.id], supporter_id_in: [supporter.id] } }]
            end
          end
        end
      end
      tab I18n.t('group.scheduled_jobs') do
        panel I18n.t('group.panel_scheduled_jobs') do
          render 'admin/groups/group_scheduled_jobs', scheduled_jobs_group_by_module_number: Group::GetScheduledJobsService.new(resource.id).call.scheduled_jobs.group_by { |job|
                                                                                               job[:module_number]
                                                                                             }
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # MEMBER ACTIONS
  # ---------------------------------------------------------------------------

  action_item :program, only: :show, if: proc { !resource.is_programmed } do
    link_to I18n.t('group.program_link'), [:program, :admin, resource]
  end

  member_action :program do
    service = Group::ProgramService.new(resource.object).call

    if service.errors.empty?
      redirect_to [:admin, resource], notice: 'Les futures tâches, envois de SMS ont été programmés avec succès.'
    else
      flash[:alert] = service.errors
      redirect_to [:admin, resource]
    end
  end

  action_item :export, only: :show do
    link_to I18n.t('group.export_link'), [:export, :admin, resource]
  end

  member_action :export do
    service = Child::ExportBooksV2Service.new(group_id: resource.id).call

    if service.errors.empty?
      send_file service.zip_file.path, type: 'application/zip', x_sendfile: true,
                                       disposition: 'attachment', filename: "#{Time.zone.today.strftime('%d-%m-%Y')}.zip"
    else
      flash[:alert] = service.errors
      redirect_back(fallback_location: root_path)
    end
  end

  action_item :distribute_child_support, only: :show do
    link_to I18n.t('group.distribute_child_support'), %i[distribute_child_supports admin group]
  end

  member_action :distribute_child_supports do
    @perform_action = perform_distribute_child_support_admin_group_path
    @calls = Airtables::Call.all_call_missions
  end

  member_action :perform_distribute_child_support, method: :post do
    name = params[:group][:name]
    child_supports_count_by_supporter = Airtables::Call.call_missions_by_name(name).map do |call_mission|
      {
        admin_user_id: Airtables::Caller.caller_id_by_airtable_caller_id(call_mission.airtable_caller_id),
        child_supports_count: call_mission.child_supports_count
      }
    end
    Group::DistributeChildSupportsToSupportersService.new(resource.model, child_supports_count_by_supporter).call
    redirect_to admin_group_path, notice: 'Appelantes attribuées'
  end

  action_item :children_support_modules_informations, only: :show do
    if resource.model.support_module_programmed.positive?
      group_without_module_zero = resource.model.started_at < DateTime.parse(ENV['MODULE_ZERO_FEATURE_START'])
      dropdown_menu 'Récupérer les informations des modules choisis' do
        (0..resource.model.support_modules_count).each do |index|
          next if index.zero? && group_without_module_zero

          ajusted_index = group_without_module_zero ? index - 1 : index
          current_module = ajusted_index == resource.model.support_module_programmed
          not_programmed = ajusted_index >= resource.model.support_module_programmed
          item_text = "Module #{index} #{'- en cours de programmation' if current_module}#{'- à venir' if not_programmed && !current_module}"
          item item_text, children_support_modules_informations_admin_group_path(index: group_without_module_zero ? index : index + 1)
        end
      end
    end
  end

  member_action :children_support_modules_informations do
    index = params[:index]
    service = Group::ChildrenSupportModulesInformationsService.new(resource.id, index).call
    send_file(
      service.zip_file.path,
      type: 'application/zip',
      x_sendfile: true,
      disposition: 'attachment',
      filename: service.zip_filename
    )
  end
end
