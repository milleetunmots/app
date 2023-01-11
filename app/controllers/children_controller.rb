class ChildrenController < ApplicationController

  SIBLINGS_COUNT = 3

  before_action :set_src_url
  before_action :find_child, only: %i[edit update]
  before_action :build_variables, only: %i[new create]
  before_action :build_child_action_path, only: %i[edit update]

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

  def create

    service = Child::CreateService.new(
      child_creation_params.merge(src_url: session[:src_url]),
      siblings_params,
      parent1_params,
      mother_params,
      father_params,
      current_registration_origin

    ).call

    if service.errors.any?
      flash.now[:error] = service.errors
      render action: :new
    else
      redirect_to created_child_path(sms_url_form: service.sms_url_form)
    end

    mother_attributes_available = !mother_attributes[:first_name].blank? || !mother_attributes[:last_name].blank? || !mother_attributes[:phone_number].blank?
    mother_attributes_valid = !mother_attributes[:first_name].blank? && !mother_attributes[:last_name].blank? && !mother_attributes[:phone_number].blank?
    father_attributes_available = !father_attributes[:first_name].blank? || !father_attributes[:last_name].blank? || !father_attributes[:phone_number].blank?
    father_attributes_valid = !father_attributes[:first_name].blank? && !father_attributes[:last_name].blank? && !father_attributes[:phone_number].blank?

    creation_impossible = (mother_attributes_available && !mother_attributes_valid) || (father_attributes_available && !father_attributes_valid) || (!mother_attributes_available && !father_attributes_available)
    if creation_impossible

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
    if current_registration_origin == 3 && @child.registration_source == "pmi" && @child.pmi_detail.blank?
      @child.errors.add(:pmi_detail, :invalid, message: "Précisez votre PMI svp!")
    end
    if current_registration_origin == 2 && @child.registration_source == "caf" && @child.registration_source_details.blank?
      @child.errors.add(:caf_detail, :invalid, message: "Précisez votre CAF svp!")
    end
    if @child.errors.none? && @child.save
      sms_url_form = "#{ENV['TYPEFORM_URL']}#child_support_id=#{@child.child_support.id}"
      message = "Bonjour ! Je suis ravie de votre inscription à notre accompagnement! Ca démarre bientôt. Pour recevoir les livres chez vous, merci de répondre à ce court questionnaire #{sms_url_form}"

      SpotHit::SendSmsService.new([@child.parent1_id], Time.now.to_i, message).call if current_registration_origin == 2
      SpotHit::SendSmsService.new([@child.parent1_id], DateTime.now.change({hour: 19}).to_i, message).call if current_registration_origin == 3

      siblings_attributes.each do |sibling_attributes|
        Child.create!(sibling_attributes.merge(
          registration_source: @child.registration_source,
          registration_source_details: @child.registration_source_details,
          parent1: @child.parent1,
          parent2: @child.parent2,
          should_contact_parent1: @child.should_contact_parent1,
          should_contact_parent2: @child.should_contact_parent2,
          pmi_detail: @child.pmi_detail,
          child_support: @child.child_support
        ))
      end
      redirect_to created_child_path(sms_url_form: sms_url_form)
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
      @new_link = new_child3_path
    when 2
      session.delete(:registration_origin)
      @message = I18n.t('inscription_success.without_widget', typeform_url: params[:sms_url_form])
      @again = false
      @widget = false
      @new_link = new_child2_path
    else
      @message = I18n.t('inscription_success.with_widget')
      @again = false
      @widget = true
      @new_link = new_child1_path
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
    result = params.require(:child).permit(:gender, :first_name, :last_name, :birthdate, :registration_source, :registration_source_details, :pmi_detail, child_support_attributes: %i[important_information])
    result.delete(:child_support_attributes) if result[:child_support_attributes][:important_information].blank?
    result
  end

  def child_update_params
    params.require(:child).permit(:group_status)
  end

  def parent1_params
    params.require(:child).permit(parent1_attributes: %i[letterbox_name address postal_code city_name])[:parent1_attributes]
  end

  def mother_params
    params.require(:child).permit(parent1_attributes: %i[first_name last_name phone_number])[:parent1_attributes]
  end

  def father_params
    params.require(:child).permit(parent2_attributes: %i[first_name last_name phone_number])[:parent2_attributes]
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
    case request.path
    when '/inscription1'
      session[:registration_origin] = 1
      @form_path = children1_path
    when '/inscription2'
      session[:registration_origin] = 2
      @form_path = children2_path
    when '/inscription3'
      session[:registration_origin] = 3
      @form_path = children3_path
    end
    @title = I18n.t("inscription_title.form#{current_registration_origin}")
    @banner = I18n.t("inscription_banner.form#{current_registration_origin}")
    case current_registration_origin
    when 3
      @terms_accepted_at_label = I18n.t('inscription_terms_accepted_at_label.pro')
      @registration_source_label = I18n.t('inscription_registration_source_label.pro')
      @registration_source_collection = :pro
      @registration_pmi_detail = I18n.t('inscription_pmi.detail')
      @registration_source_details_label = I18n.t('inscription_registration_source_details_label.pro')
      @child_min_birthdate = Date.today - 30.months
    when 2
      @terms_accepted_at_label = I18n.t('inscription_terms_accepted_at_label.parent')
      @registration_source_label = I18n.t('inscription_registration_source_label.parent')
      @registration_source_collection = :parent
      @registration_caf_detail = I18n.t('inscription_caf.detail')
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
