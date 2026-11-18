module AdminUsers
  # « Vous avez oublié votre mot de passe ? » : pages ouvertes sans être connecté.
  #
  # ApplicationController exige une session (authenticate_admin_user!) et Devise ne
  # dispense que ses propres contrôleurs, reconnus par is_a?(::DeviseController). En
  # développement, après un rechargement du code, ::DeviseController est une nouvelle
  # classe : le contrôleur d'ActiveAdmin, chargé une seule fois, hérite encore de
  # l'ancienne, n'est plus reconnu, et la page renvoyait à la connexion. Comme pour
  # AdminUsers::SessionsController, la dispense est donc explicite.
  #
  # Pas de session ouverte après la réinitialisation (config.sign_in_after_reset_password
  # à false) : le second facteur reste exigé à la connexion suivante.
  class PasswordsController < ActiveAdmin::Devise::PasswordsController

    skip_before_action :authenticate_admin_user!
    skip_before_action :set_paper_trail_whodunnit
  end
end
