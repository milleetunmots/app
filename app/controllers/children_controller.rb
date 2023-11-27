class ChildrenController < ApplicationController

  SIBLINGS_COUNT = 3

  before_action :set_src_url
  before_action :find_child, only: %i[edit update]
  before_action :build_variables, only: %i[new create]
  before_action :build_child_action_path, only: %i[edit update]

  def new
    puts "FORM ORIGIN: #{current_registration_origin}"
    @child = Child.new
    build_child_for_form
  end

  def edit
    @action_path = update_child_path(id: @child.id, security_code: @child.security_code)
  end

  def create
    service = Child::CreateService.new(
      child_creation_params.merge(src_url: session[:src_url]),
      siblings_params,
      parent1_params,
      mother_params,
      father_params,
      current_registration_origin,
      @child_min_birthdate
    ).call

    @child = service.child

    if @child.errors.any?
      flash.now[:error] = "L'inscription de l'enfant a échoué"
      build_child_for_form
      render action: :new
    else
      redirect_to created_child_path(sms_url_form: service.sms_url_form)
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
      @new_link = new_pmi_registration_path
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
    result = params.require(:child).permit(:gender, :first_name, :last_name, :birthdate, :registration_source, :registration_source_details, :pmi_detail,
                                           child_support_attributes: %i[important_information])
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
                                    %i[gender first_name last_name birthdate]
                                  ])[:siblings]&.values || []
  end

  def find_child
    @child = Child.where(
      id: params[:id],
      security_code: params[:security_code]
    ).first

    head :not_found and return if @child.nil?
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
      @form_path = new_pmi_registration_path
    end
    @title = I18n.t("inscription_title.form#{current_registration_origin}")
    @banner = I18n.t("inscription_banner.form#{current_registration_origin}")
    case current_registration_origin
    when 3
      @terms_accepted_at_label = I18n.t('inscription_terms_accepted_at_label.pro')
      @source_label = I18n.t('source_label.pmi')
      @source_collection = :pmi
      @source_details_label = I18n.t('inscription_registration_source_details_label.pro')
      @child_min_birthdate = Time.zone.today - 30.months
    when 2
      @terms_accepted_at_label = I18n.t('inscription_terms_accepted_at_label.parent')
      @source_label = I18n.t('inscription_registration_source_label.caf')
      @source_collection = :caf
      @registration_caf_detail = I18n.t('inscription_caf.detail')
      @source_details_label = I18n.t('inscription_registration_source_details_label.parent')
      @child_min_birthdate = Child.min_birthdate
    else
      @terms_accepted_at_label = I18n.t('inscription_terms_accepted_at_label.parent')
      @source_label = I18n.t('inscription_registration_source_label.parent')
      @source_collection = :parent
      @source_details_label = I18n.t('inscription_registration_source_details_label.parent')
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

  def build_child_for_form
    @child.build_parent1 if @child.parent1.nil?
    @child.build_parent2 if @child.parent2.nil?
    @child.build_child_support if @child.child_support.nil?
    @child.build_children_source
    @child.siblings.build until @child.siblings.size >= SIBLINGS_COUNT
    @child.siblings.each do |sibling|
      sibling.build_child_support if sibling.child_support.nil?
    end
  end
end
