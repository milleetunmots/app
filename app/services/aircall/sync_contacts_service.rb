module Aircall
  class SyncContactsService

    CHILDREN_REGEX = /Enfant\(s\):\s*(.*)\n/.freeze
    CHILD_SUPPORT_LINK_REGEX = /Fiche de suivi:\s*(\S+)/.freeze
    CURRENT_CHILD_REGEX = /Enfant principal:\s*(\S+)/.freeze

    attr_reader :errors, :created_ids, :updated_info_ids, :updated_phone_ids

    def initialize
      @created_ids = []
      @updated_info_ids = []
      @updated_phone_ids = []
      @errors = []
    end

    def call
      Parent.with_a_child_in_active_group.find_each do |parent|
        @parent = parent
        if @parent.aircall_id.nil?
          create_contact
        else
          update_contact
        end
      end
      self
    end

    private

    def create_contact
      service = Aircall::CreateContactService.new(parent_id: @parent.id).call
      handle_errors(service.errors)
      @created_ids << @parent.id if service.errors.empty?
    end

    def update_contact
      @aircall_datas = @parent.aircall_datas
      return unless @aircall_datas

      if @aircall_datas['phone_numbers']&.first['value'].to_i != @parent.phone_number.to_i
        service = Aircall::UpdateContactPhoneNumberService.new(parent_id: @parent.id).call
        handle_errors(service.errors)
        @updated_phone_ids << @parent.id if service.errors.empty?
      end
      if @parent.aircall_datas['first_name'] != @parent.first_name || @parent.aircall_datas['last_name'] != @parent.last_name || parent_informations_changed?
        service = Aircall::UpdateContactService.new(parent_id: @parent.id).call
        handle_errors(service.errors)
        @updated_info_ids << @parent.id if service.errors.empty?
      end
    end

    def handle_errors(errors)
      @errors << "Parent #{@parent.id}: #{errors}" if errors.any?
    end

    def parent_informations_changed?
      information = @aircall_datas['information']
      children_match = information.match(CHILDREN_REGEX)
      child_support_link_match = information.match(CHILD_SUPPORT_LINK_REGEX)
      current_child_link_match = information.match(CURRENT_CHILD_REGEX)

      return true unless children_match && child_support_link_match && current_child_link_match

      children = children_match[1]
      child_support_link = child_support_link_match[1]
      current_child_link = current_child_link_match[1]

      return true unless @parent.children.decorate.map(&:name).join(', ').in?(children)
      return true unless Rails.application.routes.url_helpers.admin_child_support_url(id: @parent.current_child.child_support_id).in?(child_support_link)
      !Rails.application.routes.url_helpers.admin_child_url(id: @parent.current_child.id).in?(current_child_link)
    end
  end
end
