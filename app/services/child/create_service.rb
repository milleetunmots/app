class Child

  class CreateService

    attr_reader :child, :sms_url_form, :parent1_target_profile, :children_under_four_months, :youngest_child_under_twenty_four_months

    def initialize(attributes, siblings_attributes, parent1_attributes, parent2_attributes, registration_origin, children_source_attributes, child_min_birthdate)
      @attributes = attributes
      @registration_origin = registration_origin
      @child_min_birthdate = child_min_birthdate
      @siblings_attributes = siblings_attributes
      @parent1_attributes = parent1_attributes.merge(terms_accepted_at: Time.zone.now)
      @parent2_attributes = parent2_attributes.merge(terms_accepted_at: Time.zone.now)
      @children_source_attributes = children_source_attributes
      return unless @registration_origin == 4

      @parent1_with_supported_child = Child.includes(:parent1).where(parent1: { phone_number_national: @parent1_attributes[:phone_number] }).where(group_status: %w[active disengaged stopped]).any?
      @old_parent_target = old_parent_registration&.target_profile?
      @parent1_target_profile = parent1_target_profile?
    end

    def call
      add_registration_origin_as_tag
      add_target_tag_and_handle_children_not_supported
      build
      set_should_contact_parent
      build_siblings
      detect_errors
      if @child.errors.empty? && @child.save
        send_form_by_sms
        send_not_supported_sms
        create_parent_registration
        send_instagram_message
        @children_under_four_months = @child.siblings.all? { |child| child.months < 4 }
        younguest_child_over_four_months = @child.siblings.where('birthdate <= ?', 4.months.ago).order('birthdate desc').first
        @youngest_child_under_twenty_four_months = @children_under_four_months ? false : younguest_child_over_four_months.months < 24
      end
      self
    end

    private

    def old_parent_registration
      ParentsRegistration.where(
        parent1_phone_number: @parent1_attributes[:phone_number],
        parent2_phone_number: @parent2_attributes[:phone_number] == '' ? nil : @parent2_attributes[:phone_number]
      ).first
    end

    def parent1_target_profile?
      return true if @parent1_with_supported_child

      return false if @old_parent_target == false

      return true if @parent1_attributes[:degree_country_at_registration] == 'other'

      @parent1_attributes[:degree_level_at_registration].in? %w[no_degree brevet bep_cap bac]
    end

    def add_registration_origin_as_tag
      # add tags for bao / local_partner ?
      @attributes[:tag_list] ||= []
      @attributes[:tag_list] << case @registration_origin
                                when 5 then 'inscription5'
                                when 4 then 'inscription4'
                                when 3 then 'inscription3'
                                when 2 then 'inscriptioncaf'
                                else 'inscription1'
                                end
    end

    def add_target_tag_and_handle_children_not_supported
      return unless @registration_origin == 4

      if @parent1_target_profile
        add_target_tag('filtre-diplome-OK')
      else
        add_target_tag('filtre-diplome-KO')
        set_not_supported
      end
    end

    def add_target_tag(tag)
      @attributes[:child_support_attributes] ||= {}
      @attributes[:child_support_attributes][:tag_list] ||= []
      @attributes[:tag_list] << tag
      @attributes[:child_support_attributes][:tag_list] << tag
    end

    def set_not_supported
      return unless 'filtre-diplome-KO'.in?(@attributes[:tag_list]) && @registration_origin == 4

      @attributes[:group_status] = 'not_supported'
    end

    def build
      @attributes.merge!(children_source_attributes: @children_source_attributes)
      parent1_attributes = @parent1_attributes.merge(parent1_present? ? @parent1_attributes : @parent2_attributes).merge(tag_list: @attributes[:tag_list])
      parent2_attributes = @parent1_attributes.merge(@parent2_attributes).merge(tag_list: @attributes[:tag_list]) if parent2_present? && parent1_present?
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
        attributes[:tag_list] = @child.tag_list
        attributes[:children_source_attributes] = @children_source_attributes
        next unless @registration_origin == 4

        attributes[:group_status] = @child.group_status
      end
      @child.siblings.build(@siblings_attributes)
    end

    def detect_errors
      @child.valid?
      if any_parent?
        parent1_validation if parent1_present?
        parent2_validation if parent2_present?
      end
      source_validation
      birthdate_validation
      overseas_child_validation
    end

    def send_form_by_sms
      return if 'filtre-diplome-KO'.in? @child.tag_list

      @sms_url_form = "#{ENV.fetch('TYPEFORM_URL', nil)}#child_support_id=#{@child.child_support.id}"
      message = "1001mots: Bonjour ! Je suis ravie de votre inscription à notre accompagnement ! Si vous avez 3 minutes, merci de répondre à ce court questionnaire #{@sms_url_form}"

      SpotHit::SendSmsService.new([@child.parent1_id], Time.zone.now.to_i, message).call if @registration_origin.in?([2, 4])
      SpotHit::SendSmsService.new([@child.parent1_id], Time.zone.now.change({ hour: 18 }).to_i, message).call if @registration_origin.in?([3, 5])
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

    def source_validation
      @child.errors.add(:source, :invalid) unless Source.active.exists?(@children_source_attributes[:source_id])
    end

    def overseas_child_validation
      return unless @parent1_attributes[:postal_code].to_i / 1000 == 97

      @child.errors.add(:base,
                        :invalid,
                        message: "L'accompagnement 1001mots n'est pas encore disponible dans votre région. N'hésitez pas à suivre nos actualités sur notre site et notre page facebook !")
    end

    def send_not_supported_sms
      return unless @registration_origin == 4 && 'filtre-diplome-KO'.in?(@child.tag_list)

      media = Media::Form.find_or_create_by(name: 'Lien - non accompagnement', url: ENV['NOT_SUPPORTED_LINK'])
      message = "1001mots : Bonjour ! Suite à votre demande d'inscription, nous regrettons de ne pas pouvoir accompagner votre enfant. Les places sont limitées et attribuées selon des critères spécifiques. Toutefois, nous avons préparé un ensemble de conseils qui peuvent aider votre enfant à développer son langage. Vous les trouverez ici : {URL}"
      ProgramMessageService.new(Time.zone.now.next_day(3).strftime('%d-%m-%Y'), '12:30', ["child.#{@child.id}"], message, nil, media.redirection_target.id, false, nil, nil, ['not_supported']).call
    end

    def send_instagram_message
      message = "1001mots : En attendant que votre accompagnement 1001mots commence, retrouvez sur Instagram nos idées d’activités et nos conseils pour occuper #{@child.first_name}, abonnez-vous ! https://www.instagram.com/association_1001mots"
      SpotHit::SendSmsService.new([@child.parent1_id], Time.zone.now.advance(days: 3).change({ hour: 18 }).to_i, message, nil, nil, false, nil, nil, %w[active waiting]).call
    end

    def create_parent_registration
      return unless @registration_origin == 4

      parent_registration = ParentsRegistration.new(
        parent1: @child.parent1,
        target_profile: @parent1_target_profile,
        parent1_phone_number: @child.parent1.phone_number_national
      )
      if @child.parent2
        parent_registration.parent2 = @child.parent2
        parent_registration.parent2_phone_number = @child.parent2.phone_number_national
      end
      parent_registration.save!
    end
  end
end
