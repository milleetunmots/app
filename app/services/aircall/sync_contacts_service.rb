module Aircall
  class SyncContactsService

    CHILD_SUPPORT_LINK_REGEX = /Fiche de suivi:\s*(\S+)/.freeze
    GROUP_REGEX = /Cohorte:\s*(.*)\n/.freeze

    attr_reader :errors, :created_ids, :updated_info_ids, :updated_phone_ids

    def initialize
      @created_ids = []
      @updated_info_ids = []
      @updated_phone_ids = []
      @errors = []
    end

    def call
      return self unless ENV['AIRCALL_ENABLED']

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
      company_name = @aircall_datas['company_name']
      child_support_link_match = information.match(CHILD_SUPPORT_LINK_REGEX)
      group_match = information.match(GROUP_REGEX)
      return true unless company_name == @parent.children.map(&:first_name).join(', ')
      return true unless child_support_link_match && group_match

      child_support_link = child_support_link_match[1]
      group_match = group_match[1]
      return true unless Rails.application.routes.url_helpers.edit_admin_child_support_url(id: @parent.current_child.child_support_id).in?(child_support_link)

      @parent.current_child.group_name != group_match
    end
  end
end
