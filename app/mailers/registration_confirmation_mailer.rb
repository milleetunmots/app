class RegistrationConfirmationMailer < ApplicationMailer
  default from: ENV['MAIL_SENDER'] || 'inscription-no-reply@1001mots.org'

  def confirmation(child_id, recipient_email)
    @child = Child.find(child_id)
    @parent = @child.parent1
    mail(to: recipient_email, subject: I18n.t('registration_confirmation_email.email_subject', first_name: @child.first_name))
  rescue StandardError => e
    Rollbar.error(e, 'RegistrationConfirmationMailer#confirmation', child_id: child_id, recipient_email: recipient_email)
    raise
  end
end
