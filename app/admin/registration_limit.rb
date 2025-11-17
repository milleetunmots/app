ActiveAdmin.register RegistrationLimit do

  menu priority: 2, parent: 'Source'

  decorate_with RegistrationLimitDecorator

  actions :all, except: [:destroy]

  includes :source

  index row_class: ->(registration_limit) { "archived-row" if registration_limit.is_archived? }, download_links: false do
    selectable_column
    id_column
    column :source
    column :start_date
    column :end_date
    column :limit
    column :children_count
    column :state
    column :registration_link
    column :registration_url_params
    column :form_status
    column :is_archived
    actions defaults: true do |registration_limit|
      if registration_limit.is_archived?
        link_to "Désarchiver", unarchive_admin_registration_limit_path(registration_limit), method: :put, class: "member_link"
      else
        link_to "Archiver", archive_admin_registration_limit_path(registration_limit), method: :put, class: "member_link"
      end
    end
  end

  scope :all, group: :all, default: true
  scope(I18n.t('activerecord.attributes.registration_limit.not_closed')) do |scope|
    scope.merge(RegistrationLimit.active)
  end
  scope(I18n.t('activerecord.attributes.registration_limit.is_archived')) do |scope|
    scope.merge(RegistrationLimit.archived)
  end

  form do |f|
    f.semantic_errors(*f.object.errors.keys)
    f.inputs do
      f.input :source,
              input_html: { data: { select2: {} } }
      f.input :start_date, as: :datepicker
      f.input :without_end_date, as: :boolean
      f.input :end_date, as: :datepicker
      f.input :limit, input_html: { type: 'number' }
      f.input :registration_link,
              collection: registration_form_select_collection,
              input_html: { data: { select2: {} } }
      f.input :registration_url_params, input_html: { placeholder: 'utm_source=caf01&utm_medium=mail&utm_caf=caf01' }
      f.input :is_archived
      f.actions
    end
  end

  permit_params :source_id, :start_date, :end_date, :limit, :registration_link_id, :registration_url_params, :is_archived

  action_item :archive, only: :show, if: proc { !resource.is_archived? } do
    link_to 'Archiver', [:archive, :admin, resource], method: :put
  end

  action_item :unarchive, only: :show, if: proc { resource.is_archived? } do
    link_to 'Désarchiver', [:unarchive, :admin, resource], method: :put
  end

  member_action :archive, method: :put do
    resource.archive!
    redirect_to [:admin, resource], notice: "La limite a été archivée."
  end

  member_action :unarchive, method: :put do
    resource.unarchive!
    redirect_to [:admin, resource], notice: "La limite a été désarchivée."
  end

end
