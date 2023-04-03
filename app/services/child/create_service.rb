class Child
  class CreateService

    attr_reader :child, :sms_url_form

    def initialize(
      attributes,
      siblings_attributes,
      parent1_attributes,
      mother_attributes,
      father_attributes,
      registration_origin,
      child_min_birthdate)
      @attributes = attributes
      @registration_origin = registration_origin
      @child_min_birthdate = child_min_birthdate
      @siblings_attributes = siblings_attributes
      @parent1_attributes = parent1_attributes
      @mother_attributes = mother_attributes.merge(gender: 'f', terms_accepted_at: Time.now)
      @father_attributes = father_attributes.merge(gender: 'm', terms_accepted_at: Time.now)
    end

    def call
      add_registration_origin_as_tag
      build
      set_should_contact_parent
      build_siblings
      detect_errors
      if @child.errors.empty?
        send_form_by_sms if @child.save
      end

      self
    end

    private

    def add_registration_origin_as_tag
      @attributes[:tag_list] = case @registration_origin
                               when 3 then 'form-pro'
                               when 2 then 'form-2'
                               else 'site'
                               end
    end

    def build
      parent1_attributes = @parent1_attributes.merge( mother_present? ? @mother_attributes : @father_attributes)
      parent2_attributes = @parent1_attributes.merge( @father_attributes ) if father_present? && mother_present?

      if parent2_attributes.nil?
        @child = Child.new(@attributes.merge(parent1_attributes: parent1_attributes))
      else
        @child = Child.new(@attributes.merge(parent1_attributes: parent1_attributes, parent2_attributes: parent2_attributes))
      end
    end

    def set_should_contact_parent
      @child.should_contact_parent1 =  true
      @child.should_contact_parent2 = father_present? && mother_present?
    end

    def build_siblings
      @siblings_attributes.each do |attributes|
        attributes[:registration_source] = @child.registration_source
        attributes[:registration_source_details] = @child.registration_source_details
        attributes[:parent1] = @child.parent1
        attributes[:parent2] = @child.parent2
        attributes[:should_contact_parent1] = @child.should_contact_parent1
        attributes[:should_contact_parent2] = @child.should_contact_parent2
        attributes[:pmi_detail] = @child.pmi_detail
        attributes[:child_support] = @child.child_support
      end
      @child.siblings.build(@siblings_attributes)
    end

    def send_form_by_sms
      @sms_url_form = "#{ENV['TYPEFORM_URL']}#child_support_id=#{@child.child_support.id}"
      message = "Bonjour ! Je suis ravie de votre inscription à notre accompagnement! Ca démarre bientôt. Pour recevoir les livres chez vous, merci de répondre à ce court questionnaire #{@sms_url_form}"

      SpotHit::SendSmsService.new([@child.parent1_id], Time.now.to_i, message).call if @registration_origin == 2
      SpotHit::SendSmsService.new([@child.parent1_id], DateTime.now.change({hour: 19}).to_i, message).call if @registration_origin == 3
    end

    def mother_present?
      @mother_attributes[:first_name].present? || @mother_attributes[:last_name].present? || @mother_attributes[:phone_number].present?
    end

    def father_present?
      @father_attributes[:first_name].present? || @father_attributes[:last_name].present? || @father_attributes[:phone_number].present?
    end

    def any_parent?
      if !mother_present? && !father_present?
        @child.errors.add(:base, :invalid_parents, message: 'Au moins un parent est obligatoire.')
        return false
      end
      true
    end

    def mother_validation
      @child.errors.add("parent1_first_name", :blank) unless @mother_attributes[:first_name].present?
      @child.errors.add("parent1_last_name", :blank) unless @mother_attributes[:last_name].present?
      @child.errors.add("parent1_phone_number_national", :blank) unless @mother_attributes[:phone_number].present?
    end

    def father_validation
      @child.errors.add("parent2_first_name", :blank) unless @father_attributes[:first_name].present?
      @child.errors.add("parent2_last_name", :blank) unless @father_attributes[:last_name].present?
      @child.errors.add("parent2_phone_number_national", :blank) unless @father_attributes[:phone_number].present?
    end

    def birthdate_validation
      if @child.birthdate < @child_min_birthdate
        @child.errors.add(:birthdate, :invalid, message: "minimale: #{(@child_min_birthdate)}")
      end
    end

    def pmi_detail_validation
      if @registration_origin == 3 && @child.registration_source == "pmi" && @child.pmi_detail.blank?
        @child.errors.add(:pmi_detail, :invalid, message: "Précisez votre PMI svp!")
      end
    end

    def caf_detail_validation
      if @registration_origin == 2 && @child.registration_source == "caf" && @child.registration_source_details.blank?
        @child.errors.add(:caf_detail, :invalid, message: "Précisez votre CAF svp!")
      end
    end

    def detect_errors
      @child.valid?
      if any_parent?
        mother_validation if mother_present?
        father_validation if father_present?
      end

      birthdate_validation
      pmi_detail_validation
      caf_detail_validation
    end
  end
end
