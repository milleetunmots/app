namespace :resend_form_by_sms do
  desc 'resend typeform to june24 families'
  task to_june_children: :environment do
    group = Group.find(82)
    time = Time.zone.parse('2024-06-01 11:00:00')
    url_form = 'https://form.typeform.com/to/IbaVa2kj'
    message = "L'accompagnement 1001mots commence lundi prochain pour {PRENOM_ENFANT} découvrez ce qui vous attend en cliquant ici : "
    group.child_supports.each do |child_support|
      next unless child_support.tag_list.include?('relance_01')

      message_with_url_form = "#{message} #{url_form}#child_support_id=#{child_support.id}".gsub(/{PRENOM_ENFANT}/, child_support.current_child&.first_name || 'votre enfant')
      SpotHit::SendSmsService.new([child_support.parent1.id], time.to_i, message_with_url_form).call
    end
  end
end
