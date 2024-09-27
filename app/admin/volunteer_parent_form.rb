ActiveAdmin.register_page 'Volunteer Parent Form' do
  menu false

  content title: 'Parent bénévole' do
    form action: admin_volunteer_parent_form_perform_path, method: :post, id: 'volunter-parent-form' do |f|
      f.input :authenticity_token, type: :hidden, name: :authenticity_token, value: form_authenticity_token
      f.input :parent1_id, type: :hidden, name: :parent1_id, value: params[:parent1_id]
      f.input :parent2_id, type: :hidden, name: :parent2_id, value: params[:parent2_id]
      f.input :child_support_id, type: :hidden, name: :child_support_id, value: params[:child_support_id]

      div do
        if params[:parent2_id].present?
          div id: 'select-parent-volunteer' do
            label class: 'label-for-group' do
              'Lequel de ces parents pourrait être un parent bénévole selon toi ?'
            end
            div class: 'form-checkbox-input' do
              f.input :parent1, type: :checkbox, id: 'select-parent-1', class: 'select-parent', name: :parent1
              label "#{Parent.find(params[:parent1_id]).decorate.name} (Parent 1)"
            end
            div class: 'form-checkbox-input' do
              f.input :parent2, type: :checkbox, id: 'select-parent-2', class: 'select-parent', name: :parent2
              label "#{Parent.find(params[:parent2_id]).decorate.name} (Parent 2)"
            end
            hr
          end
        end
        div id: 'select-parent-volunteer-reason' do
          label class: 'label-for-group' do
            'Ce parent pourrait être bénévole pour 1001mots car :'
          end
          div class: 'radio-input' do
            f.input :reason, type: :radio, value: :parent, name: :reason, class: 'parent-volunteer-reason-radio'
            label "C'est lui qui m'en a parlé."
          end
          div class: 'radio-input' do
            f.input :reason, type: :radio, value: :caller, name: :reason, class: 'parent-volunteer-reason-radio'
            label "On n'en a pas parlé mais c'est mon sentiment."
          end
          div do
            small do
              'Pour plus d’infos sur comment les parents peuvent contribuer bénévolement : cliquez '.html_safe +
              link_to(
                'ici',
                'https://magical-bull-428.notion.site/Les-parents-ambassadeurs-a-veut-dire-quoi-a63cf7a2a4664f41a1380e6030381dbe?pvs=4',
                target: '_blank')
            end
          end
          hr
        end
        div id: 'parent-volunteer-form-details' do
          label class: 'label-for-group' do
            "Pourquoi penses-tu que ça pourrait l’intéresser ?"
          end
          span "(facultatif)"
          textarea name: :details
        end
        div class: 'actions' do
          div class: 'action input_action' do
            input type: 'submit', value: 'Valider', id: 'parent_volunteer-form-submit'
          end
        end
      end
    end
  end

  page_action :perform, method: :post do
    if params[:parent2_id].present?
      update_parent(params[:parent1_id], params[:details]) if params[:parent1].present?
      update_parent(params[:parent2_id], params[:details]) if params[:parent2].present?
    else
      update_parent(params[:parent1_id], params[:details])
    end

    notice = 'Potentiel parent bénévole ajouté'
    redirect_to admin_child_support_path(params[:child_support_id]), notice: notice
  end

  controller do
    def update_parent(parent_id, details = nil)
      return unless parent_id.present?

      parent = Parent.find(parent_id)
      parent.is_ambassador = true
      parent.is_ambassador_detail = details if details
      return if parent.save

      alert = "Erreur lors de la sauvegarde (Contactez l'équipe tech)"
      redirect_to admin_child_support_path(params[:child_support_id]), alert: alert
    end
  end
end
