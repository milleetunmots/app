class ChildrenController < ApplicationController

  SIBLINGS_COUNT = 3

  skip_before_action :authenticate_admin_user!
  before_action :set_src_url
  before_action :find_child, only: %i[edit update eval_form]
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
    render action: :new and return if @form_path.in?(ENV['BLOCKED_REGISTRATION_PATHS'].split(','))
    service = Child::CreateService.new(
      child_creation_params.merge(src_url: session[:src_url]),
      siblings_params,
      parent1_params,
      parent2_params,
      current_registration_origin,
      children_source_params,
      @child_min_birthdate
    ).call

    @child = service.child

    if @child.errors.any?
      flash.now[:error] = "L'inscription de l'enfant a échoué"
      build_child_for_form
      @child.build_children_source(source_id: children_source_params&.dig(:source_id), details: children_source_params&.dig(:details), registration_department: children_source_params&.dig(:registration_department))
      render action: :new
    elsif current_registration_origin == 2 && ENV['CAF_SUBSCRIPTION'].present?
      redirect_to created_child_path(caf_subscripted_child_id: @child.id)
    elsif @child.source.name == ENV['CAF93'] && ENV['EVAL25'].present?
      current_child =
        if @child.siblings.length > 1
         @child.siblings.find { |sibling| sibling.months >= 16 && sibling.months <= 30 } || @child
        else
          @child
        end
      redirect_to created_child_path(eval_25_child_id: current_child.id)
    elsif service.parent1_target_profile || current_registration_origin != 4
      redirect_to created_child_path(sms_url_form: service.sms_url_form, children_under_four_months: service.children_under_four_months, youngest_child_under_twenty_four_months: service.youngest_child_under_twenty_four_months)
    else
      redirect_to created_child_path(sms_url_form: service.sms_url_form, parent1: @child.parent1, children_under_four_months: service.children_under_four_months, youngest_child_under_twenty_four_months: service.youngest_child_under_twenty_four_months)
    end
  end

  def created
    support_wait_time_message =
      case params[:children_under_four_months]
      when 'true'
        'inscription_success.without_widget_but_with_children_under_four_months'
      else
        if params[:youngest_child_under_twenty_four_months] == 'true'
          'inscription_success.neither_widget_nor_child_under_four_months_with_youngest_child_under_twenty_four_months'
        else
          'inscription_success.neither_widget_nor_child_under_four_months_without_youngest_child_under_twenty_four_months'
        end
      end

    case current_registration_origin
    when 5
      @message = I18n.t('inscription_success.pro_local_partners')
      @again = true
      @widget = false
      @new_link = new_local_partner_registration_path
    when 4
      @widget = false
      if params[:parent1]
        @again = false
        @with_parent_no_target = true
        @message = I18n.t('inscription_success.with_parent_no_target')
      else
        @message = I18n.t(support_wait_time_message, typeform_url: params[:sms_url_form])
        @again = true
        @new_link = new_bao_registration_path
      end
    when 3
      # for this form we keep the registration_origin
      # so that multiple children can be registered
      @message = I18n.t('inscription_success.pro_pmi')
      @again = true
      @widget = false
      @new_link = new_pmi_registration_path
    when 2
      if ENV['CAF_SUBSCRIPTION'].present?
        @child_id = params[:caf_subscripted_child_id]
        set_caf_subscription_form_variables
      elsif ENV['EVAL25'].present? && params[:eval_25_child_id].present?
        @child_id = params[:eval_25_child_id]
        set_eval25_form_variables
      else
        session.delete(:registration_origin)
        @message = I18n.t(support_wait_time_message, typeform_url: params[:sms_url_form])
        @again = false
        @widget = false
        @new_link = new_caf_registration_path
      end
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

  def eval_form
    @child_id = @child.id
    @ccn = @child.first_name
    @pln = @child.parent1.last_name
    @pfn = @child.parent1.first_name
    @ccm = @child.months
  end

  private

  def set_eval25_form_variables
    child = Child.find(@child_id)
    @eval25 = true
    @ccn = child.first_name
    @ccm = child.months
    @pfn = child.parent1.first_name
    @pln = child.parent1.last_name
  end

  def set_caf_subscription_form_variables
    child = Child.find(@child_id)
    @st = child.parent1.security_token
    @caf_subscription_form = true
    @ccn = child.first_name
    @pln = child.parent1.last_name
    @email = child.parent1.email
    @ccm = child.months
  end

  def child_creation_params
    params.require(:child).permit(:gender, :first_name, :last_name, :birthdate, { tag_list: [] }, child_support_attributes: %i[important_information tag_list]).tap do |param|
      param[:tag_list] = param[:tag_list].is_a?(String) ? param[:tag_list].split : param[:tag_list]
      param[:child_support_attributes] = param[:child_support_attributes].to_h
    end
  end

  def child_update_params
    params.require(:child).permit(:group_status)
  end

  def parent1_params
    params.require(:child).permit(parent1_attributes: %i[letterbox_name address postal_code city_name first_name last_name phone_number gender degree_level_at_registration degree_country_at_registration address_supplement email book_delivery_organisation_name book_delivery_location])[:parent1_attributes]
  end

  def parent2_params
    params.require(:child).permit(parent2_attributes: %i[first_name last_name phone_number gender preferred_channel])[:parent2_attributes]
  end

  def siblings_params
    params.require(:child).permit(siblings: [
                                    %i[gender first_name last_name birthdate]
                                  ])[:siblings]&.values || []
  end

  def children_source_params
    params.require(:child).permit(children_source_attributes: %i[source_id details registration_department])[:children_source_attributes]
  end

  def utm_caf_params
    params[:utm_caf] && Source.exists?(utm: params[:utm_caf]) ? params[:utm_caf] : nil
  end

  def pmi_dpt_params
    params[:pmi_dpt] && Source.by_pmi.where(department: params[:pmi_dpt]).any? ? params[:pmi_dpt] : nil
  end

  def utm_params
    params.keys.select { |key| I18n.transliterate(key).downcase.start_with?('utm') }
  end

  def tags_by_utm_params
    utm_params.map { |utm_param| I18n.transliterate("#{utm_param}=#{params[utm_param]}").downcase }
  end

  def find_child
    @child =
      if params[:st].present?
        Child.find_by(security_token: params[:st])
      else
        Child.where(
          id: params[:id],
          security_code: params[:security_code] || params[:sc]
        ).first
      end

    head :not_found and return if @child.nil?
  end

  def build_variables
    case request.path
    when '/inscription'
      @form_path = children_path
      @form_path_url = children_path(request.query_parameters)
    when '/inscription1'
      session[:registration_origin] = 1
      @form_path = children1_path
      @form_path_url = children1_path(request.query_parameters)
    when '/inscriptioncaf'
      session[:registration_origin] = 2
      @form_path = caf_registration_path
      @form_path_url = caf_registration_path(request.query_parameters)
    when '/inscription3'
      session[:registration_origin] = 3
      @form_path = pmi_registration_path
      @form_path_url = pmi_registration_path(request.query_parameters)
    when '/inscription4'
      session[:registration_origin] = 4
      @form_path = bao_registration_path
      @form_path_url = bao_registration_path(request.query_parameters)
    when '/inscription5'
      session[:registration_origin] = 5
      @form_path = local_partner_registration_path
      @form_path_url = local_partner_registration_path(request.query_parameters)
    end
    @title = I18n.t("inscription_title.form#{current_registration_origin}")
    @banner = I18n.t("inscription_banner.form#{current_registration_origin}")
    case current_registration_origin
    when 5
      @terms_accepted_at_label = I18n.t('inscription_terms_accepted_at_label.pro')
      @source_collection = :local_partner
      @source_label = I18n.t('source_label.local_partner')
      @source_details_label = I18n.t('source_details_label.pro')
      @source_registration_department_label = I18n.t('source_department_label')
      @child_min_birthdate = Time.zone.today - 30.months
    when 4
      @terms_accepted_at_label = I18n.t('inscription_terms_accepted_at_label.parent')
      @source_collection = :bao
      @source_label = I18n.t('source_label.parent')
      @source_details_label = I18n.t('source_details_label.referral')
      @child_min_birthdate = Child.min_birthdate
      @degree_level_label = "Dernier diplôme obtenu (ou équivalence)"
      @degree_obtained_in_label = "Dans quel pays ce diplôme a-t-il été obtenu ?"
    when 3
      @terms_accepted_at_label = I18n.t('inscription_terms_accepted_at_label.pro')
      @source_collection = :pmi
      @pmi_dpt = pmi_dpt_params
      @source_label = I18n.t('source_label.pmi')
      @source_details_label = I18n.t('source_details_label.pro')
      @child_min_birthdate = Time.zone.today - 30.months
    when 2
      @terms_accepted_at_label = I18n.t('inscription_terms_accepted_at_label.parent')
      @source_collection = :caf
      @form_received_from = I18n.t('form_received_from')
      @source_label = I18n.t('source_label.caf')
      @utm_caf = utm_caf_params
      @registration_caf_detail = I18n.t('inscription_caf.details')
      @source_details_label = I18n.t('source_details_label.parent')
      @child_min_birthdate = Child.min_birthdate
    else
      @terms_accepted_at_label = I18n.t('inscription_terms_accepted_at_label.parent')
      @source_label = I18n.t('source_label.parent')
      @source_collection = :parent
      @source_details_label = I18n.t('source_details_label.parent')
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
    @child.build_parent1 unless @child.parent1
    @child.build_parent2 unless @child.parent2
    @child.build_child_support unless @child.child_support
    @child.build_children_source unless @child.children_source
    @child.siblings.build until @child.siblings.size >= SIBLINGS_COUNT
    @child.siblings.each do |sibling|
      sibling.build_child_support unless sibling.child_support
    end
    @child.tag_list = tags_by_utm_params
  end
end
