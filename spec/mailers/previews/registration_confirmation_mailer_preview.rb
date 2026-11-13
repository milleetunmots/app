class RegistrationConfirmationMailerPreview < ActionMailer::Preview
  def confirmation
    RegistrationConfirmationMailer.confirmation(Child.last.id, 'prenom.nom@exemple.fr')
  end
end
