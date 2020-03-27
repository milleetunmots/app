class AdminUserDecorator < BaseDecorator

  def email_link
    h.mail_to model.email
  end

end
