class ChildrenController < ApplicationController

  def new
    @child = Child.new
    @child.build_parent1
    @child.build_parent2
  end

  def create
    attributes = child_params
    attributes.merge!(parent2_params) unless attributes[:parent2_absent] == '1'
    @child = Child.new(attributes)
    if @child.save
      flash[:success] = 'Inscription effectuée'
      redirect_to action: :new
    else
      flash.now[:error] = 'Inscription refusée'
      if @child.parent2_absent == '1'
        @child.build_parent2
      end
      render action: :new
    end
  end

  private

  def child_params
    params.require(:child).permit(:gender, :first_name, :last_name, :birthdate, :parent2_absent,
                                  parent1_attributes: parent_params
                                 )
  end

  def parent2_params
    params.require(:child).permit(parent2_attributes: parent_params)
  end

  def parent_params
    %i(first_name last_name email phone_number gender address postal_code city_name terms_accepted_at)
  end

end
