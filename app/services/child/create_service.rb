class Child
  class CreateService

    attr_reader :errors, :sms_url_form

    def initialize(
      attributes,
      siblings_attributes,
      parent1_attributes,
      mother_attributes,
      father_attributes,
      registration_origin)
      @attributes = attributes
      @registration_origin = registration_origin
      @siblings_attributes = siblings_attributes
      @parent1_attributes = parent1_attributes
      @mother_attributes = mother_attributes.merge(gender: 'f', terms_accepted_at: Time.now)
      @father_attributes = father_attributes.merge(gender: 'm', terms_accepted_at: Time.now)
      @errors = []
    end

    def call
      add_registration_origin_as_tag
      build
      set_should_contact_parent
      build_siblings
      @child.save!
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


    private

    def mother_present?
      @mother_attributes[:first_name].present? && @mother_attributes[:last_name].present? && @mother_attributes[:phone_number].present?
    end

    def father_present?
      @father_attributes[:first_name].present? && @father_attributes[:last_name].present? && @father_attributes[:phone_number].present?
    end

    def send_form
      sms_url_form = "#{ENV['TYPEFORM_URL']}#child_support_id=#{@child.child_support.id}"
      message = "Bonjour ! Je suis ravie de votre inscription à notre accompagnement! Ca démarre bientôt. Pour recevoir les livres chez vous, merci de répondre à ce court questionnaire #{sms_url_form}"

      SpotHit::SendSmsService.new([@child.parent1_id], Time.now.to_i, message).call if current_registration_origin == 2
      SpotHit::SendSmsService.new([@child.parent1_id], DateTime.now.change({hour: 19}).to_i, message).call if current_registration_origin == 3
    end
  end
end
