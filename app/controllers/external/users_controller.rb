class External::UsersController < External::BaseController
  load_and_authorize_resource class: 'ExternalUser'

  def index
    @users = ExternalUser.where(source_id: current_user.source_id)
  end

  def new
    @user = ExternalUser.new
  end

  def create
    @user = ExternalUser.new(user_params)
    @user.source_id = current_user.source_id

    if @user.save
      redirect_to external_users_path, notice: "Utilisateur créé avec succès."
    else
      render :new
    end
  end

  def edit
  end

  def update
    @user.skip_password_validation = true
    if @user.update(user_params)
      redirect_to external_users_path, notice: "Utilisateur mis à jour avec succès."
    else
      render :edit
    end
  end

  def destroy
    if @user.pmi_admin?
      redirect_to external_users_path, alert: "Vous ne pouvez pas supprimer un admin de PMI."
    else
      @user.destroy
      redirect_to external_users_path, notice: "Utilisateur supprimé avec succès."
    end
  end


  private

  def user_params
    params.require(:external_user).permit(:email, :password, :role)
  end
end
