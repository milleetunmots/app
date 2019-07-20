ActiveAdmin.register ChildSupport do

  decorate_with ChildSupportDecorator

  has_paper_trail
  has_tasks

  actions :all, except: [:new]

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  includes :children, :supporter

  index do
    selectable_column
    id_column
    column :children
    column :supporter, sortable: :supporter_id
    column :should_be_read
    column I18n.t('child_support.call1') do |model|
      [model.call1_status, model.call1_parent_progress_index].join(' ').html_safe
    end
    column I18n.t('child_support.call2') do |model|
      [model.call2_status, model.call2_program_investment_index].join(' ').html_safe
    end
    column I18n.t('child_support.call3') do |model|
      [model.call3_status, model.call3_program_investment_index].join(' ').html_safe
    end
    column :created_at do |model|
      l model.created_at.to_date, format: :default
    end
    column :updated_at do |model|
      l model.updated_at.to_date, format: :default
    end
    actions
  end

  scope(:mine, default: true) { |scope| scope.supported_by(current_admin_user) }
  scope :all

  filter :should_be_read,
         input_html: { data: { select2: { width: '100%' } } }
  filter :supporter,
         input_html: { data: { select2: {} } }
  filter :call1_status
  filter :call1_parent_progress_present,
         as: :boolean,
         label: proc { I18n.t('child_support.call1_parent_progress_present') }
  filter :call1_parent_progress,
         as: :select,
         collection: proc { child_support_call1_parent_progress_select_collection },
         input_html: { multiple: true, data: { select2: {} } }
  filter :call2_status
  filter :call2_program_investment_present,
         as: :boolean,
         label: proc { I18n.t('child_support.call2_program_investment_present') }
  filter :call2_program_investment,
         as: :select,
         collection: proc { child_support_call2_program_investment_select_collection },
         input_html: { multiple: true, data: { select2: {} } }
  filter :call3_status
  filter :call3_program_investment_present,
         as: :boolean,
         label: proc { I18n.t('child_support.call3_program_investment_present') }
  filter :call3_program_investment,
         as: :select,
         collection: proc { child_support_call3_program_investment_select_collection },
         input_html: { multiple: true, data: { select2: {} } }
  filter :created_at
  filter :updated_at

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form(remote: true) do |f|
    f.inputs do
      columns do
        column do
          f.input :supporter,
                  input_html: { data: { select2: {} } }
          # parents & children
          columns do
            # parents
            [
              [f.object.parent1, f.object.should_contact_parent1],
              [f.object.parent2, f.object.should_contact_parent2]
            ].each do |p|
              next if p[0].nil?
              parent = p[0].decorate
              should_contact_parent = p[1]

              column do
                render 'parent', parent: parent, should_contact_parent: should_contact_parent
              end
            end
            column do
              # children
              f.object.children.each do |c|
                child = c.decorate

                render 'child', child: child
              end
            end
          end
        end
        column do
          f.label :important_information
          f.input :important_information, label: false, input_html: { rows: 5, style: 'width: 100%' }
          f.input :should_be_read
        end
      end
      tabs do
        tab I18n.t('child_support.call1') do
          columns do
            column do
              f.input :call1_status, input_html: { style: 'width: 70%' }
              f.input :call1_duration, input_html: { style: 'width: 70%' }
            end
            column do
              f.input :call1_status_details, input_html: { rows: 5, style: 'width: 70%' }
            end
          end
          columns do
            column do
              f.input :call1_parent_actions,
                      input_html: {
                        rows: 8,
                        style: 'width: 70%',
                        value: f.object.call1_parent_actions.presence || (
                          I18n.t('child_support.default.call1_parent_actions')
                        )
                      }
              f.input :call1_parent_progress,
                      as: :radio,
                      collection: child_support_call1_parent_progress_select_collection
            end
            column do
              f.input :call1_language_development, input_html: { rows: 8, style: 'width: 70%' }
              f.input :call1_notes, input_html: { rows: 8, style: 'width: 70%' }
            end
          end
        end
        tab I18n.t('child_support.call2') do
          columns do
            column do
              f.input :call2_status, input_html: { style: 'width: 70%' }
              f.input :call2_duration, input_html: { style: 'width: 70%' }
            end
            column do
              f.input :call2_status_details, input_html: { rows: 5, style: 'width: 70%' }
            end
          end
          columns do
            column do
              f.input :call2_technical_information, input_html: { rows: 8, style: 'width: 70%' }
              f.input :call2_content_usage,
                      input_html: {
                        rows: 8,
                        style: 'width: 70%',
                        value: f.object.call2_content_usage.presence || (
                          I18n.t('child_support.default.call2_content_usage')
                        )
                      }
              f.input :call2_program_investment,
                      as: :radio,
                      collection: child_support_call2_program_investment_select_collection
            end
            column do
              f.input :call2_language_development, input_html: { rows: 8, style: 'width: 70%' }
              f.input :call2_goals, input_html: { rows: 8, style: 'width: 70%' }
              f.input :call2_notes, input_html: { rows: 8, style: 'width: 70%' }
            end
          end
        end
        tab I18n.t('child_support.call3') do
          columns do
            column do
              f.input :call3_status, input_html: { style: 'width: 70%' }
              f.input :call3_duration, input_html: { style: 'width: 70%' }
            end
            column do
              f.input :call3_status_details, input_html: { rows: 5, style: 'width: 70%' }
            end
          end
          columns do
            column do
              f.input :call3_technical_information, input_html: { rows: 8, style: 'width: 70%' }
              f.input :call3_content_usage,
                      input_html: {
                        rows: 8,
                        style: 'width: 70%',
                        value: f.object.call3_content_usage.presence || (
                          I18n.t('child_support.default.call3_content_usage')
                        )
                      }
              f.input :call3_program_investment,
                      as: :radio,
                      collection: child_support_call3_program_investment_select_collection
            end
            column do
              f.input :call3_language_development, input_html: { rows: 8, style: 'width: 70%' }
              f.input :call3_goals, input_html: { rows: 8, style: 'width: 70%' }
              f.input :call3_notes, input_html: { rows: 8, style: 'width: 70%' }
            end
          end
        end
      end
    end
    f.actions
  end

  permit_params :important_information, :supporter_id, :should_be_read,
                :call1_duration, :call1_status, :call1_status_details,
                :call1_parent_actions, :call1_parent_progress,
                :call1_language_development, :call1_notes,
                :call2_duration, :call2_status, :call2_status_details,
                :call2_technical_information, :call2_content_usage,
                :call2_program_investment, :call2_language_development,
                :call2_goals, :call2_notes,
                :call3_duration, :call3_status, :call3_status_details,
                :call3_technical_information, :call3_content_usage,
                :call3_program_investment, :call3_language_development,
                :call3_goals, :call3_notes

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    attributes_table title: I18n.t('child_support.base') do
      row :supporter
      row :parent1
      row :parent2
      row :children
      row :important_information
      row :should_be_read
      row :created_at
      row :updated_at
    end
    attributes_table title: I18n.t('child_support.call1') do
      row :call1_status
      row :call1_status_details
      row :call1_duration
      row :call1_parent_actions
      row :call1_parent_progress
      row :call1_language_development
      row :call1_notes
    end
    attributes_table title: I18n.t('child_support.call2') do
      row :call2_status
      row :call2_status_details
      row :call2_duration
      row :call2_technical_information
      row :call2_content_usage
      row :call2_program_investment
      row :call2_language_development
      row :call2_goals
      row :call2_notes
    end
    attributes_table title: I18n.t('child_support.call3') do
      row :call3_status
      row :call3_status_details
      row :call3_duration
      row :call3_technical_information
      row :call3_content_usage
      row :call3_program_investment
      row :call3_language_development
      row :call3_goals
      row :call3_notes
    end
  end

end
