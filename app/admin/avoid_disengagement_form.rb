ActiveAdmin.register_page 'Avoid Disengagement Form' do
  menu false

  content title: "Formulaire de poursuite de l’accompagnement" do

    form action: admin_avoid_disengagement_form_perform_path, method: :post, id: 'restart-support-form' do |f|
      f.input :authenticity_token, type: :hidden, name: :authenticity_token, value: form_authenticity_token
      f.input :child_support_id, type: :hidden, name: :child_support_id, value: params[:child_support_id]
      f.input :call_index, type: :hidden, name: :call_index, value: params[:call_index]

      div do
        label class: 'label-for-group' do
          "Raison(s) de la poursuite de l'accompagnement (plusieurs choix possibles) :"
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
    call_index = params['call_index']

    avoid_disengagement_service = ChildSupport::AvoidDisengagementService.new(
      current_admin_user.id,
      params[:child_support_id],
      reason,
      details,
      call_index
    ).call

    if avoid_disengagement_service.error.nil?
      redirect_to admin_child_support_path(params[:child_support_id]), notice: 'La famille ne sera pas désengagée'
    else
      redirect_to admin_child_support_path(params[:child_support_id]), alert: restart_support_service.error
    end
  end
end
