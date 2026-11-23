class Child

  class CreateService

    PARENT_IDENTITY_ATTRIBUTES = %i[first_name last_name phone_number gender email degree_level_at_registration degree_country_at_registration].freeze

    attr_reader :child, :sms_url_form, :parent1_target_profile, :children_under_four_months, :youngest_child_under_twenty_four_months

    def initialize(attributes, siblings_attributes, parent1_attributes, parent2_attributes, registration_origin, children_source_attributes)
      @attributes = attributes.to_h.deep_dup
      @registration_origin = registration_origin
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
      reject_ai_sourced_registration
      set_should_contact_parent
      build_siblings
      detect_errors
      if @child.errors.empty? && @child.save
        @sms_url_form = initial_form_url
        Child::SendSignUpMessagesService.new(@child, @registration_origin).call
        create_parent_registration
        add_caf_subscription_tag
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
                                when 6 then 'inscriptionmsa'
                                when 5 then 'inscriptionpartenaires'
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
      @attributes[:tag_list] ||= []
      @attributes[:tag_list] << tag
      @attributes[:child_support_attributes][:tag_list] << tag
    end

    def set_not_supported
      return unless 'filtre-diplome-KO'.in?(@attributes[:tag_list]) && @registration_origin == 4

      @attributes[:group_status] = 'not_supported'
    end

    # Inscriptions arrivées via une URL proposée par une IA générative : ni
    # financées, ni ciblées. Contrairement au filtre diplôme ci-dessus, la règle
    # s'applique quelle que soit l'origine de l'inscription. Appelée avant
    # `build_siblings`, qui recopie alors le statut sur la fratrie.
    def reject_ai_sourced_registration
      @child.group_status = 'not_supported' if @child.ai_sourced_registration?
    end

    def build
      @attributes.merge!(children_source_attributes: @children_source_attributes)
      parent1_attributes = @parent1_attributes.merge(parent1_present? ? @parent1_attributes : @parent2_attributes).merge(tag_list: @attributes[:tag_list])
      parent2_attributes = @parent1_attributes.except(*PARENT_IDENTITY_ATTRIBUTES).merge(@parent2_attributes).merge(tag_list: @attributes[:tag_list]) if parent2_present? && parent1_present?
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
      share_group_status = @registration_origin == 4 || @child.ai_sourced_registration?
      @siblings_attributes.each do |attributes|
        attributes[:parent1] = @child.parent1
        attributes[:parent2] = @child.parent2
        attributes[:should_contact_parent1] = @child.should_contact_parent1
        attributes[:should_contact_parent2] = @child.should_contact_parent2
        attributes[:child_support] = @child.child_support
        attributes[:tag_list] = @child.tag_list
        attributes[:children_source_attributes] = @children_source_attributes
        attributes[:group_status] = @child.group_status if share_group_status
      end
      @child.siblings.build(@siblings_attributes)
    end

    def detect_errors
      present_parents = { 1 => @parent1_attributes, 2 => @parent2_attributes }.select { |index, _| index == 1 ? parent1_present? : parent2_present? }
      Child::ValidateRegistrationService.new(
        @child, present_parents: present_parents, parent1_postal_code: @parent1_attributes[:postal_code], source_id: @children_source_attributes[:source_id]
      ).call
    end

    def parent1_present?
      @parent1_attributes[:first_name].present? || @parent1_attributes[:last_name].present? || @parent1_attributes[:phone_number].present? || @parent1_attributes[:gender].present?
    end

    def parent2_present?
      @parent2_attributes[:first_name].present? || @parent2_attributes[:last_name].present? || @parent2_attributes[:phone_number].present?
    end

    def initial_form_url
      Rails.application.routes.url_helpers.initial_typeform_url(st: @child.parent1.security_token)
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

    def add_caf_subscription_tag
      return unless @registration_origin == 2 && ENV['CAF_SUBSCRIPTION'].present?

      caf = Source.find_by(channel: 'caf', department: '93', is_archived: false)
      return unless caf && @child.source == caf

      tag = Tag.find_or_create_by(name: 'inscrit_via_caf_93')
      @child.child_support.tag_list << tag
      @child.child_support.save
      @child.siblings.each do |child|
        child.tag_list << tag
        child.save
      end
    end
  end
end
