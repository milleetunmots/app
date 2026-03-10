class AdminUser
  class ExportToSheetService < ApiGoogle::InitializeSheetsService

    def initialize(admin_user)
      super()
      @admin_user = admin_user
      @sheet_id = ENV['ADMIN_USERS_SHEET_ID']
      @sheet_name = ENV['ADMIN_USERS_SHEET_NAME']
    end

    def call
      initialize_sheets
      append_row
      self
    end

    private

    def append_row
      value_range = Google::Apis::SheetsV4::ValueRange.new(values: [row_values])
      @service.append_spreadsheet_value(
        @sheet_id,
        @sheet_name,
        value_range,
        value_input_option: 'RAW'
      )
    rescue StandardError => e
      @errors << "Erreur Google Sheets : #{e.message}"
    end

    def row_values
      [
        @admin_user.id,
        @admin_user.email,
        nil, # reset_password_token
        nil, # reset_password_sent_at
        nil, # remember_created_at
        @admin_user.sign_in_count,
        @admin_user.last_sign_in_at,
        @admin_user.current_sign_in_ip&.to_s,
        @admin_user.last_sign_in_ip&.to_s,
        @admin_user.created_at,
        @admin_user.updated_at,
        @admin_user.name,
        @admin_user.decorate.user_role,
        @admin_user.is_disabled,
        @admin_user.can_treat_task,
        @admin_user.aircall_phone_number,
        @admin_user.aircall_number_id,
        @admin_user.can_send_automatic_sms
      ]
    end
  end
end
