ActiveAdmin.register ChildSupport do

  decorate_with ChildSupportDecorator

  has_paper_trail
  has_tasks

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  includes :children

  index do
    selectable_column
    id_column
    column :children
    column :call1_parent_progress
    column :call2_program_investment
    column :call3_program_investment
    column :created_at do |model|
      l model.created_at.to_date, format: :default
    end
    column :updated_at do |model|
      l model.updated_at.to_date, format: :default
    end
    actions
  end

  filter :call1_parent_progress,
         as: :check_boxes,
         collection: Hash[ChildSupport::PARENT_PROGRESS.map{|v| [ChildSupport.human_attribute_name("call1_parent_progress.#{v}"), v]}]
  filter :call2_program_investment,
         as: :check_boxes,
         collection: Hash[ChildSupport::PROGRAM_INVESTMENT.map{|v| [ChildSupport.human_attribute_name("call2_program_investment.#{v}"), v]}]
  filter :call3_program_investment,
         as: :check_boxes,
         collection: Hash[ChildSupport::PROGRAM_INVESTMENT.map{|v| [ChildSupport.human_attribute_name("call3_program_investment.#{v}"), v]}]
  filter :created_at
  filter :updated_at

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.inputs do
      columns do
        column do
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
                (
                  div parent.admin_link(with_icon: true, target: '_blank')
                ) + (
                  div parent.phone_number
                ) + (
                  div parent.email
                ) + (
                  div style: "margin-top: 5px" do
                    if should_contact_parent
                      status_tag 'yes', label: t('should_be_contacted')
                    else
                      status_tag 'no', label: t('should_not_be_contacted')
                    end
                  end
                )
              end
            end
            column do
              # children
              f.object.children.each do |c|
                child = c.decorate

                (
                  div child.admin_link(with_icon: true, target: '_blank')
                ) + (
                  div child.age
                )
              end
            end
          end
        end
        column do
          f.label :important_information
          f.input :important_information, label: false, input_html: { rows: 5, style: 'width: 100%' }
        end
      end
      tabs do
        tab :call1 do
          columns do
            column do
              f.input :call1_parent_actions, input_html: { rows: 5 }
              f.input :call1_parent_progress,
                      as: :radio,
                      collection: Hash[ChildSupport::PARENT_PROGRESS.map{|v| [ChildSupport.human_attribute_name("call1_parent_progress.#{v}"),v]}]
            end
            column do
              f.input :call1_language_development, input_html: { rows: 5 }
              f.input :call1_notes, input_html: { rows: 5 }
            end
          end
        end
        tab :call2 do
          columns do
            column do
              f.input :call2_technical_information, input_html: { rows: 5 }
              f.input :call2_content_usage, input_html: { rows: 5 }
              f.input :call2_language_development, input_html: { rows: 5 }
            end
            column do
              f.input :call2_program_investment,
                      as: :radio,
                      collection: Hash[ChildSupport::PROGRAM_INVESTMENT.map{|v| [ChildSupport.human_attribute_name("call2_program_investment.#{v}"),v]}]
              f.input :call2_goals, input_html: { rows: 5 }
              f.input :call2_notes, input_html: { rows: 5 }
            end
          end
        end
        tab :call3 do
          columns do
            column do
              f.input :call3_technical_information, input_html: { rows: 5 }
              f.input :call3_content_usage, input_html: { rows: 5 }
              f.input :call3_language_development, input_html: { rows: 5 }
            end
            column do
              f.input :call3_program_investment,
                      as: :radio,
                      collection: Hash[ChildSupport::PROGRAM_INVESTMENT.map{|v| [ChildSupport.human_attribute_name("call3_program_investment.#{v}"),v]}]
              f.input :call3_goals, input_html: { rows: 5 }
              f.input :call3_notes, input_html: { rows: 5 }
            end
          end
        end
      end
    end
    f.actions
  end

  permit_params :important_information,
                :call1_parent_actions, :call1_parent_progress,
                :call1_language_development, :call1_notes,
                :call2_technical_information, :call2_content_usage,
                :call2_program_investment, :call2_language_development,
                :call2_goals, :call2_notes,
                :call3_technical_information, :call3_content_usage,
                :call3_program_investment, :call3_language_development,
                :call3_goals, :call3_notes

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  # show do
  #   attributes_table do
  #     row :parent1
  #     row :should_contact_parent1
  #     row :parent2
  #     row :should_contact_parent2
  #     row :first_name
  #     row :last_name
  #     row :birthdate
  #     row :age
  #     row :gender
  #     row :created_at
  #     row :updated_at
  #   end
  # end

end
