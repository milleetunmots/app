module Aircall
  class SyncContactsService

    CURRENT_CHILD_ID_REGEX = /\/children\/(\d+)/

    attr_reader :errors

    def initialize
      @errors = []
    end

    def call
      Parent.with_a_child_in_active_group.each do |parent|
        @parent = parent
        if @parent.aircall_id.nil?
          create_contact
        else
          update_contact
        end
      end
    end

    private

    def create_contact
      @service = Aircall::CreateContactService.new(parent: @parent).call
      handle_errors
    end

    def update_contact
      @aircall_datas = @parent.aircall_datas
      return unless @aircall_datas

      if @aircall_datas['phone_numbers']&.first['value'] != @parent.phone_number
        puts "update phone numbers"
        @service = Aircall::UpdateContactPhoneNumberService.new(parent: @parent).call
        handle_errors
      end
      if @parent.aircall_datas['first_name'] != @parent.first_name || @parent.aircall_datas['last_name'] != @parent.last_name || !parent_informations_changed?
        puts "update contact"
        @service = Aircall::UpdateContactService.new(parent: @parent).call
      end
    end

    def handle_errors
      @errors << @service.errors if @service.errors.any?
    end

    def parent_informations_changed?
      match = @aircall_datas['information'].match(CURRENT_CHILD_ID_REGEX)
      return false unless match

      match[1]&.to_i == @parent.current_child.id
    end
  end
end
