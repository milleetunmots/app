namespace :send_form_by_sms do
  desc 'clear sidekiq'
  task to_june_children: :environment do
    group = Group.find(82)
    time = Time.zone.parse('2024-05-30 14:00:00')
    url_form = 'https://form.typeform.com/to/IbaVa2kj'
    message = "SMS : 1001mots, c'est bien plus que des livres. Découvrez ce que vous allez recevoir à partir de lundi prochain pour {PRENOM_ENFANT} en cliquant ici :"
    group.child_supports.each do |child_support|
      message_with_url_form = "#{message} #{url_form}#child_support_id=#{child_support.id}"
      SpotHit::SendSmsService.new([child_support.parent1.id], time.to_i, message_with_url_form).call
    end
  end
end
