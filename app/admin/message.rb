ActiveAdmin.register_page "Message" do
  
  menu  priority: 12, parent: 'Programmer des envois'

  content do

    form action: admin_message_program_sms_path, method: :post, id: 'sms-form' do |f|
      f.input :authenticity_token, type: :hidden, name: :authenticity_token, value: form_authenticity_token
      
      label 'Date et heure d\'envoie du message'
      div class: 'datetime-container' do
        input type: 'text', id: 'date-send', name: 'date_sent', class: 'datepicker hasDatePicker', style: 'margin-right: 20px;', value: Date.today
        input type: 'time', id: 'time-send', name: 'hour_sent', value: Time.zone.now.strftime('%H:%M')
      end
      
      div do
        label 'Choisissez les destinataires'
        select name: 'recipients[]', multiple: 'multiple', id: 'recipients' do
          optgroup label: 'Parents' do
            Parent.all.each do |parent|
              option value: 'parent.'+parent.id.to_s do parent.first_name+' '+ parent.last_name end
            end
          end
        end
      end


      div do
        label 'Message'
        textarea name: 'message'
      end

      div class: 'actions' do
        div class: 'action input_action' do
          input type: 'submit', value: 'Valider'
        end
      end
    end
  end


  page_action :program_sms, method: :post do
    redirect_back(fallback_location: root_path, notice: 'Message programmé')
  end

end
