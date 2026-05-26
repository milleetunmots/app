class RegistrationConfirmationMailer < ApplicationMailer
  default from: ENV['MAIL_SENDER'] || 'bot@1001mots.org'

  def confirmation(child_id, recipient_email)
    @child = Child.find(child_id)
    @parent = @child.parent1
    mail(to: recipient_email, subject: I18n.t('registration_confirmation_email.email_subject', first_name: @child.first_name))
  end
end