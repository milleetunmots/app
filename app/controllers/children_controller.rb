class ChildrenController < ApplicationController

  SIBLINGS_COUNT = 3

  before_action :set_src_url
  before_action :find_child, only: %i(edit update)
  before_action :build_variables, only: %i(new create)
  before_action :build_child_action_path, only: %i(edit update)

  def new
    puts "FORM ORIGIN: #{current_registration_origin}"
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

  def new1
    session[:registration_origin] = 1
    redirect_to action: :new
  end

  def new2
    session[:registration_origin] = 2
    redirect_to action: :new
  end

  def new3
    session[:registration_origin] = 3
    redirect_to action: :new
  end

  def create
    attributes = child_creation_params.merge(
      src_url: session[:src_url]
    )

    # Tags

    attributes[:tag_list] =
      case current_registration_origin
      when 3 then 'form-pro'
      when 2 then 'form-2'
      else 'site'
      end

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

    child_first_name_exists = Child.exists?(first_name: attributes[:first_name])
    mother_exists = Parent.exists?(first_name: mother_attributes[:first_name], last_name: mother_attributes[:last_name])
    father_exists = Parent.exists?(first_name: father_attributes[:first_name], last_name: father_attributes[:last_name])

    if (mother_attributes_available && !mother_attributes_valid) || (father_attributes_available && !father_attributes_valid) || (!mother_attributes_available && !father_attributes_available)
      flash.now[:error] = "Inscription refusée"
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
      attributes[:should_contact_parent1] = true

      if father_attributes_available
        # father data is also available: use it as parent 2 (we know for sure that it is valid)
        attributes[:parent2_attributes] = parent1_attributes.merge(father_attributes)
        attributes[:should_contact_parent2] = true
      end
    else
      # mother data is not available: use father as parent 1 (we know for sure that it is present and valid)
      attributes[:parent1_attributes] = parent1_attributes.merge(father_attributes)
      attributes[:should_contact_parent1] = true
    end

    # Base

    @child = Child.new(attributes)
    if @child.birthdate < @child_min_birthdate
      @child.errors.add(:birthdate, :invalid, message: "minimale: #{l(@child_min_birthdate)}")
    end
    if child_first_name_exists && (mother_exists || father_exists)
      @child.errors.add(:last_name, :invalid, message: "existe déja")
      @child.errors.add(:first_name, :invalid, message: "existe déja")
      @child.errors.add(:birthdate, :invalid, message: "existe déja")
    end
    if @child.errors.none? && @child.save
      siblings_attributes.each do |sibling_attributes|
        Child.create!(sibling_attributes.merge(
          registration_source: @child.registration_source,
          registration_source_details: @child.registration_source_details,
          parent1: @child.parent1,
          parent2: @child.parent2,
          child_support: @child.child_support
        ))
      end
      redirect_to created_child_path
    else
      flash.now[:error] = "Inscription refusée"
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
    case current_registration_origin
    when 3
      # for this form we keep the registration_origin
      # so that multiple children can be registered
      @message = I18n.t('inscription_success.pro')
      @again = true
      @widget = false
    when 2
      session.delete(:registration_origin)
      @message = I18n.t('inscription_success.without_widget')
      @again = false
      @widget = false
    else
      @message = I18n.t('inscription_success.with_widget')
      @again = false
      @widget = true
    end
    session.delete(:src_url)
  end

  def edit
    @action_path = update_child_path(id: @child.id, security_code: @child.security_code)
  end

  def update
    @child.attributes = child_update_params
    if @child.save(validate: false)
      redirect_to updated_child_path
    else
      render action: :edit
    end
  end

  private

  def child_creation_params
    result = params.require(:child).permit(:gender, :first_name, :last_name, :birthdate, :registration_source, :registration_source_details, child_support_attributes: %i(important_information))
    result.delete(:child_support_attributes) if result[:child_support_attributes][:important_information].blank?
    result
  end

  def child_exists?

  end

  def child_update_params
    params.require(:child).permit(:has_quit_group)
  end

  def parent1_params
    params.require(:child).permit(parent1_attributes: %i(letterbox_name address postal_code city_name))[:parent1_attributes]
  end

  def mother_params
    params.require(:child).permit(parent1_attributes: %i(first_name last_name phone_number))[:parent1_attributes]
  end

  def father_params
    params.require(:child).permit(parent2_attributes: %i(first_name last_name phone_number))[:parent2_attributes]
  end

  def siblings_params
    params.require(:child).permit(siblings: [
      [:gender, :first_name, :last_name, :birthdate]
    ])[:siblings]&.values || []
  end

  def find_child
    @child = Child.where(
      id: params[:id],
      security_code: params[:security_code]
    ).first

    head 404 and return if @child.nil?
  end

  def build_variables
    @title = I18n.t("inscription_title.form#{current_registration_origin}")
    @banner = I18n.t("inscription_banner.form#{current_registration_origin}")
    case current_registration_origin
    when 3
      @terms_accepted_at_label = I18n.t('inscription_terms_accepted_at_label.pro')
      @registration_source_label = I18n.t('inscription_registration_source_label.pro')
      @registration_source_collection = :pro
      @registration_source_details_label = I18n.t('inscription_registration_source_details_label.pro')
      @child_min_birthdate = Date.today - 30.months
    when 2
      @terms_accepted_at_label = I18n.t('inscription_terms_accepted_at_label.parent')
      @registration_source_label = I18n.t('inscription_registration_source_label.parent')
      @registration_source_collection = :parent
      @registration_source_details_label = I18n.t('inscription_registration_source_details_label.parent')
      @child_min_birthdate = Child.min_birthdate
    else
      @terms_accepted_at_label = I18n.t('inscription_terms_accepted_at_label.parent')
      @registration_source_label = I18n.t('inscription_registration_source_label.parent')
      @registration_source_collection = :parent
      @registration_source_details_label = I18n.t('inscription_registration_source_details_label.parent')
      @child_min_birthdate = Child.min_birthdate_alt
    end
  end

  def build_child_action_path
    @child_action_path = update_child_path(id: @child.id, security_code: @child.security_code)
  end

  def current_registration_origin
    session[:registration_origin] || 1
  end

  def set_src_url
    session[:src_url] ||= request.url
  end
end
