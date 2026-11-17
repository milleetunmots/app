class RegistrationConfirmationMailer < ApplicationMailer
  default from: ENV['MAIL_SENDER'] || 'inscription-no-reply@1001mots.org'
  layout false

  def confirmation(child_id, recipient_email)
    @child = Child.find(child_id)
    @parent = @child.parent1
    attachments.inline['logo-1001mots.png'] = logo
    mail(to: recipient_email, subject: I18n.t('registration_confirmation_email.email_subject', first_name: @child.first_name))
  rescue StandardError => e
    Rollbar.error(e, 'RegistrationConfirmationMailer#confirmation', child_id: child_id, recipient_email: recipient_email)
    raise
  end

  private

  # Par le manifeste Sprockets et non par le fichier d'app/assets : l'image Docker de
  # staging et de production supprime app/assets après la précompilation. Le manifeste
  # lit la source en dev et en test, la version précompilée de public/assets ailleurs.
  def logo
    Rails.application.assets_manifest.find_sources('registration/logo-1001mots.png').first ||
      raise('Logo registration/logo-1001mots.png introuvable dans les assets')
  end
end
