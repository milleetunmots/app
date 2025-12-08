ActiveAdmin.register_page 'Stop Support Form' do
  menu false

  content title: "Formulaire d'arrêt de l'accompagnement" do

    form action: admin_stop_support_form_perform_path, method: :post, id: 'stop-support-form' do |f|
      f.input :authenticity_token, type: :hidden, name: :authenticity_token, value: form_authenticity_token
      f.input :child_support_id, type: :hidden, name: :child_support_id, value: params[:child_support_id]

      div do
        label class: 'label-for-group' do
          "Raison de l'arrêt de l'accompagnement"
        end
        hr
        div class: 'radio-input' do
          f.input :stop_reason, type: :radio, value: :program, name: :reason, class: 'stop-support-form-radio'
          label 'La famille ne veut pas du programme complet.'
        end
        div class: 'radio-input' do
          f.input :stop_reason, type: :radio, value: :very_advanced_practices, name: :reason, class: 'stop-support-form-radio'
          label 'La famille a des pratiques très avancées.'
        end
        div class: 'radio-input' do
          f.input :stop_reason, type: :radio, value: :problematic_case, name: :reason, class: 'stop-support-form-radio'
          label 'La famille me pose problème (insulte, propos gênants, raccroche au nez, etc).'
        end
        div class: 'radio-input' do
          f.input :stop_reason, type: :radio, value: :professional, name: :reason, class: 'stop-support-form-radio'
          label "La famille est un.e professionnel.le de santé qui souhaite tester l'accompagnement."
        end
        div class: 'radio-input' do
          f.input :stop_reason, type: :radio, value: :registered_by_partner_without_consent, name: :reason, class: 'stop-support-form-radio'
          label 'La famille a été inscrite par un partenaire sans son accord.'
        end
        div class: 'radio-input' do
          f.input :stop_reason, type: :radio, value: :family_limited_french_for_support, name: :reason, class: 'stop-support-form-radio'
          label 'La famille n’est pas assez francophone pour tirer profit de l’accompagnement.'
        end
        div class: 'radio-input' do
          f.input :stop_reason, type: :radio, value: :family_unresponsive_after_adaptation, name: :reason, class: 'stop-support-form-radio'
          label "La famille n'est pas assez francophone ; confirmation après des tentatives d'adaptation plus poussées (SMS, traduction, etc)."
        end
      end
      div id: 'form-details' do
        hr
        div class: 'form-checkbox-input' do
          f.input :validation, type: :checkbox, id: 'stop-support-form-checkbox'
          label id: 'checkbox-label' do
            ''
          end
        end
        hr
        div do
          label class: 'label-for-group' do
            'Détaillez les éléments factuels en quelques mots'
          end
          textarea name: :details
        end
        div class: 'actions' do
          div class: 'action input_action' do
            input type: 'submit', value: 'Valider', id: 'stop-support-form-submit', data: { confirm: "Je confirme vouloir arrêter l'accompagnement pour cette famille - L'arrêt est immédiat et définitif et la famille ne recevra plus de livres, de sms ou d’appels." }
          end
        end
      end
    end
  end

  page_action :perform, method: :post do
    stop_support_service = ChildSupport::CallerStopSupportService.new(
      current_admin_user.id,
      params[:child_support_id],
      params[:reason],
      params[:details]
    ).call

    if stop_support_service.error.nil?
      redirect_to admin_child_support_path(params[:child_support_id]), notice: 'Accompagnement arrêté et message de désistement envoyé aux parents'
    else
      redirect_to admin_child_support_path(params[:child_support_id]), alert: stop_support_service.error
    end
  end
end
