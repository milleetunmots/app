ActiveAdmin.register SupportModule do

  decorate_with SupportModuleDecorator

  has_paper_trail
  has_tags
  has_tasks
  use_discard

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  index do
    selectable_column
    id_column
    column :name
    column :ages
    column :tags
    column :created_at do |model|
      l model.created_at.to_date, format: :default
    end
    actions dropdown: true do |decorated|
      discard_links_args(decorated.model).each do |args|
        item *args
      end
    end
  end

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs do
      f.input :name
      f.input :ages,
              as: :radio,
              collection: support_module_ages_select_collection
      tags_input(f)
    end
    f.inputs do
      f.has_many :support_module_weeks,
                 heading: 'Semaines',
                 new_record: 'Ajouter une semaine',
                 allow_destroy: true,
                 sortable: :position,
                 sortable_start: 1 do |fmwf|
        fmwf.input :name
        fmwf.input :medium,
                   collection: support_module_week_medium_select_collection,
                   input_html: { data: { select2: {} } }
      end
    end
    f.actions
  end

  permit_params :name, :ages, :support_module_weeks,
                {
                  support_module_weeks_attributes: [:id, :name, :medium_id, :position, :_destroy]
                }.merge(tags_params)

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table do
      row :name
      row :ages
      row :tags
      row :created_at
      row :updated_at
    end
    panel '', class: 'support-module-week-lines' do
      resource.support_module_weeks.decorate.each_with_index do |support_module_week, idx|
        panel support_module_week.title(1+idx), class: 'support-module-week-line' do
          if support_module_week.medium
            columns do
              (1..3).each do |msg_idx|
                column do
                  if support_module_week.medium.send("body#{msg_idx}").blank?
                    'Vide'
                  else
                    support_module_week.medium.decorate.as_card(msg_idx)
                  end
                end
              end
            end
          else
            span 'Vide'
          end
        end
      end
    end
  end

end
