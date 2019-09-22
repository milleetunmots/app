class ChildrenController < ApplicationController

  def new
    @child = Child.new
    @child.build_parent1
    @child.build_parent2
  end

  def create
    @child = Child.new(child_params)
    if @child.save
      flash[:success] = 'Inscription effectuée'
      redirect_to action: :new
    else
      flash.now[:error] = 'Inscription refusée'
      render action: :new
    end
  end

  private

  def child_params
    parent_params = %i(first_name last_name email phone_number gender address postal_code city_name)
    params.require(:child).permit(:gender, :first_name, :last_name, :birthdate,
                                  parent1_attributes: parent_params,
                                  parent2_attributes: parent_params
                                 )
  end

end
