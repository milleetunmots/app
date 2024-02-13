class Child

  class CreateService

    attr_reader :child, :sms_url_form

    def initialize(attributes, siblings_attributes, parent1_attributes, parent2_attributes, registration_origin, children_source_attributes, child_min_birthdate)
      @attributes = attributes
      @registration_origin = registration_origin
      @child_min_birthdate = child_min_birthdate
      @siblings_attributes = siblings_attributes
      @parent1_attributes = parent1_attributes.merge(terms_accepted_at: Time.zone.now)
      @parent2_attributes = parent2_attributes.merge(terms_accepted_at: Time.zone.now)
      @children_source_attributes = children_source_attributes
    end

    def call
      add_registration_origin_as_tag
      build
      set_should_contact_parent
      build_siblings
      detect_errors
      if @child.errors.empty? && @child.save
        ChildrenSource.create(@children_source_attributes.merge(child_id: @child.id))
        send_form_by_sms
        @child.siblings.each do |sibling|
          ChildrenSource.create(@children_source_attributes.merge(child_id: sibling.id))
        end
      end
      self
    end

    private

    def add_registration_origin_as_tag
      # add tags for bao / local_partner ?
      @attributes[:tag_list] = case @registration_origin
                               when 3 then 'form-pro'
                               when 2 then 'form-2'
                               else 'site'
                               end
    end

    def build
      parent1_attributes = @parent1_attributes.merge(parent1_present? ? @parent1_attributes : @parent2_attributes)
      parent2_attributes = @parent1_attributes.merge(@parent2_attributes) if parent2_present? && parent1_present?

      @child = if parent2_attributes.nil?
                 Child.new(@attributes.merge(parent1_attributes: parent1_attributes))
               else
                 Child.new(@attributes.merge(parent1_attributes: parent1_attributes, parent2_attributes: parent2_attributes))
               end
    end

    def set_should_contact_parent
      @child.should_contact_parent1 = true
      @child.should_contact_parent2 = parent2_present? && parent1_present?
    end

    def build_siblings
      @siblings_attributes.each do |attributes|
        attributes[:parent1] = @child.parent1
        attributes[:parent2] = @child.parent2
        attributes[:should_contact_parent1] = @child.should_contact_parent1
        attributes[:should_contact_parent2] = @child.should_contact_parent2
        attributes[:child_support] = @child.child_support
      end
      @child.siblings.build(@siblings_attributes)
    end

    def send_form_by_sms
      @sms_url_form = "#{ENV.fetch('TYPEFORM_URL', nil)}#child_support_id=#{@child.child_support.id}"
      message = "1001mots: Bonjour ! Je suis ravie de votre inscription à notre accompagnement! Ca démarre bientôt. Pour recevoir les livres chez vous, merci de répondre à ce court questionnaire #{@sms_url_form}"

      SpotHit::SendSmsService.new([@child.parent1_id], Time.zone.now.to_i, message).call if @registration_origin.in?([2, 4, 5])
      SpotHit::SendSmsService.new([@child.parent1_id], Time.zone.now.change({ hour: 19 }).to_i, message).call if @registration_origin == 3
    end

    def parent1_present?
      @parent1_attributes[:first_name].present? || @parent1_attributes[:last_name].present? || @parent1_attributes[:phone_number].present? || @parent1_attributes[:gender].present?
    end

    def parent2_present?
      @parent2_attributes[:first_name].present? || @parent2_attributes[:last_name].present? || @parent2_attributes[:phone_number].present? || @parent2_attributes[:gender].present?
    end

    def any_parent?
      if !parent1_present? && !parent2_present?
        @child.errors.add(:base, :invalid_parents, message: 'Au moins un parent est obligatoire.')
        return false
      end
      true
    end

    def parent1_validation
      @child.errors.add('parent1_first_name', :blank) unless @parent1_attributes[:first_name].present?
      @child.errors.add('parent1_last_name', :blank) unless @parent1_attributes[:last_name].present?
      @child.errors.add('parent1_phone_number_national', :blank) unless @parent1_attributes[:phone_number].present?
      @child.errors.add('parent1_gender', :invalid) unless @parent1_attributes[:gender].present? && @parent1_attributes[:gender].in?(Parent::GENDERS)
    end

    def parent2_validation
      @child.errors.add('parent2_first_name', :blank) unless @parent2_attributes[:first_name].present?
      @child.errors.add('parent2_last_name', :blank) unless @parent2_attributes[:last_name].present?
      @child.errors.add('parent2_phone_number_national', :blank) unless @parent2_attributes[:phone_number].present?
      @child.errors.add('parent2_gender', :invalid) unless @parent2_attributes[:gender].present? && @parent2_attributes[:gender].in?(Parent::GENDERS)
    end

    def birthdate_validation
      @child.errors.add(:birthdate, :invalid, message: "minimale: #{@child_min_birthdate}") if @child.birthdate < @child_min_birthdate
    end

    def overseas_child_validation
      return unless @parent1_attributes[:postal_code].to_i / 1000 == 97

      @child.errors.add(:base,
                        :invalid,
                        message: "L'accompagnement 1001 mots n'est pas encore disponible dans votre région. N'hésitez pas à suivre nos actualités sur notre site et notre page facebook !")
    end

    def detect_errors
      @child.valid?
      Source.exists?(@children_source_attributes[:source_id])
      if any_parent?
        parent1_validation if parent1_present?
        parent2_validation if parent2_present?
      end

      birthdate_validation
      overseas_child_validation
    end
  end
end
