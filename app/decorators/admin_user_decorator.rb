class AdminUserDecorator < BaseDecorator

  def email_link
    h.mail_to model.email
  end

  def user_role
    AdminUser.human_attribute_name("user_role.#{model.user_role}")
  end

end
