require 'sidekiq-scheduler'

class Group::ProgramSmsToBilingualsJob < ApplicationJob

  def perform(group_id, first_sms_date)
    children = Group.find(group_id).bilingual_children.pluck(:id).map { |id| "child.#{id}" }
    first_message = "Si vous parlez une autre langue que le français à la maison, c'est une chance pour votre enfant ! Sentez-vous libre de parler dans VOTRE LANGUE si vous êtes plus à l'aise, l'important c'est de lui parler souvent !"
    second_message = "Un enfant qui entend d'autres langues que le français à la maison n'aura pas de retard de langage et apprendra le français le moment venu. Il peut mélanger plusieurs langues mais ne les confond pas. Je vous en dis plus dans cette vidéo ! {URL}"
    second_message_link_id = RedirectionTarget.joins(:medium).find_by(media: { name: 'Bilinguisme - Pour debuter - 12-17' }).id
    third_message = "La maman d'Hanaé, qui parle le créole avec sa fille, témoigne : \"N'hésitez pas à partager ce que vous êtes, et ce que ses grands-parents sont, vos valeurs, en parlant vos langues maternelles, pour savoir d'où l'on vient et pour pouvoir avancer au mieux dans le futur.\" Et chez vous, quelle langue parlez-vous avec votre enfant ?"

    first_service = ProgramMessageService.new(first_sms_date, '12:31', children, first_message).call
    raise first_service.errors.join("\n") if first_service.errors.any?

    second_service = ProgramMessageService.new(first_sms_date + 7.days, '12:31', children, second_message, nil, second_message_link_id).call
    raise second_service.errors.join("\n") if second_service.errors.any?

    third_service = ProgramMessageService.new(first_sms_date + 14.days, '12:31', children, third_message).call
    raise third_service.errors.join("\n") if third_service.errors.any?
  end
end
