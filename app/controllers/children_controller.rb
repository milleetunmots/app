class ChildrenController < ApplicationController

  SIBLINGS_COUNT = 3

  def new
    @child = Child.new
    @child.build_parent1
    @child.build_parent2
    @child.build_child_support
    until @child.siblings.size >= SIBLINGS_COUNT do
      @child.siblings.build
    end
    @child.siblings.each do |sibling|
      sibling.build_child_support
    end
  end

  def create
    attributes = child_params

    # Siblings

    siblings_attributes = siblings_params

    # Parents

    parent1_attributes = parent1_params
    mother_attributes = mother_params.merge(
      gender: 'f',
      terms_accepted_at: Time.now
    )
    father_attributes = father_params.merge(
      gender: 'm',
      terms_accepted_at: Time.now
    )

    mother_attributes_available = !mother_attributes[:first_name].blank? || !mother_attributes[:last_name].blank? || !mother_attributes[:phone_number].blank?
    mother_attributes_valid = !mother_attributes[:first_name].blank? && !mother_attributes[:last_name].blank? && !mother_attributes[:phone_number].blank?
    father_attributes_available = !father_attributes[:first_name].blank? || !father_attributes[:last_name].blank? || !father_attributes[:phone_number].blank?
    father_attributes_valid = !father_attributes[:first_name].blank? && !father_attributes[:last_name].blank? && !father_attributes[:phone_number].blank?

    if (mother_attributes_available && !mother_attributes_valid) || (father_attributes_available && !father_attributes_valid) || (!mother_attributes_available && !father_attributes_available)
      flash.now[:error] = 'Inscription refusée'
      @child = Child.new(attributes.merge(
        parent1_attributes: parent1_attributes.merge(mother_attributes),
        parent2_attributes: father_attributes
      ))
      @child.build_child_support if @child.child_support.nil?
      @child.siblings.build(siblings_attributes)
      until @child.siblings.size >= SIBLINGS_COUNT do
        @child.siblings.build
      end
      @child.siblings.each do |sibling|
        sibling.build_child_support if sibling.child_support.nil?
      end
      @child.errors.add(:base, :invalid_parents, message: 'Infos des parents non valides')
      # @child.build_parent2 if @child.parent2.nil?
      render action: :new and return
    end

    if mother_attributes_available
      # mother data is available: use it as parent 1 (we know for sure that it is valid)
      attributes[:parent1_attributes] = parent1_attributes.merge(mother_attributes)

      if father_attributes_available
        # father data is also available: use it as parent 2 (we know for sure that it is valid)
        attributes[:parent2_attributes] = parent1_attributes.merge(father_attributes)
      end
    else
      # mother data is not available: use father as parent 1 (we know for sure that it is present and valid)
      attributes[:parent1_attributes] = parent1_attributes.merge(father_attributes)
    end

    # Base

    @child = Child.new(attributes)
    if @child.save
      siblings_attributes.each do |sibling_attributes|
        Child.create!(sibling_attributes.merge(
          registration_source: @child.registration_source,
          registration_source_details: @child.registration_source_details,
          parent1: @child.parent1,
          parent2: @child.parent2
        ))
      end
      redirect_to created_child_path
    else
      flash.now[:error] = 'Inscription refusée'
      @child.build_parent2 if @child.parent2.nil?
      @child.build_child_support if @child.child_support.nil?
      @child.siblings.build(siblings_attributes)
      until @child.siblings.size >= SIBLINGS_COUNT do
        @child.siblings.build
      end
      @child.siblings.each do |sibling|
        sibling.build_child_support if sibling.child_support.nil?
      end
      render action: :new
    end
  end

  def created

  end

  private

  def child_params
    result = params.require(:child).permit(:gender, :first_name, :last_name, :birthdate, :registration_source, :registration_source_details, child_support_attributes: %i(important_information))
    result.delete(:child_support_attributes) if result[:child_support_attributes][:important_information].blank?
    result
  end

  def parent1_params
    params.require(:child).permit(parent1_attributes: %i(address postal_code city_name))[:parent1_attributes]
  end

  def mother_params
    params.require(:child).permit(parent1_attributes: %i(first_name last_name phone_number))[:parent1_attributes]
  end

  def father_params
    params.require(:child).permit(parent2_attributes: %i(first_name last_name phone_number))[:parent2_attributes]
  end

  def siblings_params
    result = params.require(:child).permit(siblings: [[:gender, :first_name, :last_name, :birthdate, child_support_attributes: %i(important_information)]])[:siblings]&.values || []
    result.each do |sibling_params|
      sibling_params.delete(:child_support_attributes) if sibling_params[:child_support_attributes][:important_information].blank?
    end
    result
  end

end
