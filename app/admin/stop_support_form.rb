ActiveAdmin.register_page 'Stop Support Form' do
  menu false

  content title: "Formulaire d'arrêt de l'accompagnement" do

    form action: admin_stop_support_form_perform_path, method: :post, id: 'stop-support-form' do |f|
      f.input :authenticity_token, type: :hidden, name: :authenticity_token, value: form_authenticity_token
      f.input :supporter_id, type: :hidden, name: :supporter_id, value: params[:supporter_id]
      f.input :child_support_id, type: :hidden, name: :child_support_id, value: params[:child_support_id]

      div do
        label class: 'label-for-group' do
          "Raison de l'arrêt de l'accompagnement"
        end
        hr
        div class: 'radio-input' do
          f.input :stop_reason, type: :radio, value: :program, name: :reason, class: 'stop-support-form-radio'
          label "La famille que j'accompagne ne veut pas du programme complet."
        end
        div class: 'radio-input' do
          f.input :stop_reason, type: :radio, value: :popi, name: :reason, class: 'stop-support-form-radio'
          label "La famille que j'accompagne a un niveau socio-économique élevé (BAC+5)."
        end
        div class: 'radio-input' do
          f.input :stop_reason, type: :radio, value: :professional, name: :reason, class: 'stop-support-form-radio'
          label "La famille que j'accompagne est en fait un.e professionnel.le de santé qui souhaite tester l'accompagnement."
        end
        div class: 'radio-input' do
          f.input :stop_reason, type: :radio, value: :problematic_case, name: :reason, class: 'stop-support-form-radio'
          label "La famille que j'accompagne me pose problème : je demande l’arrêt de l’accompagnement sur avis de ma coordinatrice."
        end
        div class: 'radio-input' do
          f.input :stop_reason, type: :radio, value: :renunciation, name: :reason, class: 'stop-support-form-radio'
          label "La famille que j'accompagne m'a notifié par SMS qu'elle ne souhaitait pas la totalité de l'accompagnement."
        end
      end
      div id: 'form-details' do
        hr
        div id: 'checkbox-input' do
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
      params[:supporter_id],
      params[:child_support_id],
      params[:reason],
      params[:details]
    ).call

    notice = params[:reason] == 'renunciation' ? 'Message de désistement envoyé au parent' : "Accompagnement arrêté et message de fin d'accompagnement envoyé"
    if stop_support_service.error.nil?
      redirect_to admin_child_support_path(params[:child_support_id]), notice: notice
    else
      redirect_to admin_child_support_path(params[:child_support_id]), alert: stop_support_service.error
    end
  end
end
