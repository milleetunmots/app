ActiveAdmin.register_page 'Restart Support Form' do
  menu false

  content title: "Formulaire de reprise de l'accompagnement" do

    form action: admin_restart_support_form_perform_path, method: :post, id: 'restart-support-form' do |f|
      f.input :authenticity_token, type: :hidden, name: :authenticity_token, value: form_authenticity_token
      f.input :child_support_id, type: :hidden, name: :child_support_id, value: params[:child_support_id]

      div do
        label class: 'label-for-group' do
          "Raison(s) de la reprise de l'accompagnement (plusieurs choix possibles) :"
        end
        hr
        div class: 'form-checkbox-input' do
          f.input :restart_reason, type: :checkbox, value: :unavailability, name: :unavailability, class: 'restart-support-form-checkbox'
          label 'La famille a eu un empêchement important (problème familial, problème de santé, vacances à l’étranger...)'
        end
        div class: 'form-checkbox-input' do
          f.input :restart_reason, type: :checkbox, value: :message_not_received, name: :message_not_received, class: 'restart-support-form-checkbox'
          label "La famille n'avait pas reçu les appels et messages (problème de téléphone...)"
        end
        div class: 'form-checkbox-input' do
          f.input :restart_reason, type: :checkbox, value: :incorrect_status, name: :incorrect_status, class: 'restart-support-form-checkbox'
          label "Le dernier appel n'était pas KO (statut mal renseigné)"
        end
        div class: 'form-checkbox-input' do
          f.input :restart_reason, type: :checkbox, value: :motivated, name: :motivated, class: 'restart-support-form-checkbox'
          label "La famille est très motivée et 1001mots a un fort potentiel d'impact sur elle"
        end
        div class: 'form-checkbox-input' do
          f.input :restart_reason, type: :checkbox, value: :other, name: :other, class: 'restart-support-form-checkbox'
          label 'Autre'
        end

      end
      div id: 'restart-support-details' do
        label class: 'label-for-group' do
          'Détaillez les éléments factuels en quelques mots'
        end
        hr
        textarea name: :details
      end
      div class: 'actions' do
        div class: 'action input_action' do
          input type: 'submit', value: 'Confirmer', id: 'restart-support-form-submit'
        end
      end
    end
  end

  page_action :perform, method: :post do
    reason = [params['unavailability'], params['message_not_received'], params['incorrect_status'], params['motivated'], params['other']].compact
    details = params['details']

    restart_support_service = ChildSupport::CallerRestartSupportService.new(
      current_admin_user.id,
      params[:child_support_id],
      reason,
      details
    ).call

    if restart_support_service.error.nil?
      redirect_to admin_child_support_path(params[:child_support_id]), notice: 'Accompagnement repris'
    else
      redirect_to admin_child_support_path(params[:child_support_id]), alert: restart_support_service.error
    end
  end
end
