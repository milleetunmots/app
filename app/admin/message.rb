ActiveAdmin.register_page "Message" do
  
  menu  priority: 12, parent: 'Programmer des envois'

  content do

    render "admin/message/new"

    form action: admin_message_program_sms_path, method: :post do |f|
      f.input :authenticity_token, type: :hidden, name: :authenticity_token, value: form_authenticity_token
      
      label do 
        'Date d\'envoie du message'
      end
      div do
        input type: 'date', id: 'date-send', name: 'date sent' do end
        input type: 'time', id: 'time-send', name: 'hour sent' do end
      end
      
      div do
        label do
          'Parents et/ou cohorte'
        end
        select name: 'search[]', multiple: 'multiple', id: 'recipients', width: '700px' do
          optgroup label: 'Tags' do
            Tag.all.each do |tag|
              option value: 'tag.'+tag.id.to_s do tag.name end
            end
          end
          optgroup label: 'Cohortes' do
          end
          optgroup label: 'Parents' do
            Parent.all.each do |parent|
              option value: 'parent.'+parent.id.to_s do parent.first_name+' '+ parent.last_name end
            end
          end
        end
      end


      div do
        label do
          'Message'
        end
        textarea name: 'message' do
        end
      end

      button do
        'Envoyer'
      end
    end
  end


  page_action :program_sms, method: :post do
    # raise params.inspect
  end

end
