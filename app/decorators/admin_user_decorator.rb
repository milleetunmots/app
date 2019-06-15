class AdminUserDecorator < BaseDecorator

  def email
    h.mail_to model.email
  end

end
