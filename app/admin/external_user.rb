ActiveAdmin.register ExternalUser do
  menu false
  permit_params :email, :password, :password_confirmation
end
