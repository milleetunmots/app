require 'google/apis/sheets_v4'
require 'googleauth'

class Child
  class SendEvalMessageService

    CREDENTIALS = Base64.decode64(ENV['GOOGLE_CREADENTIALS_JSON']).freeze
    SCOPE = ['https://www.googleapis.com/auth/spreadsheets'].freeze
    MESSAGE = ''.freeze
    EVAL_MESSAGE_TAG = 'lien_eval25_envoye'.freeze

    attr_reader :errors

    def initialize
      @errors = []
    end

    def call
      initialize_sheets_service
      @response = @service.get_spreadsheet_values(ENV['FAMILY_SUPPORTS_SHEET_ID'], ENV['FAMILY_SUPPORTS_SHEET_NAME'])
      if @response.values.empty?
        @errors << 'Aucune donnée trouvée'
        return self
      end

      @response.values.each do |row|
        @child = nil
        byebug
        next if row[1].blank? || row[6].blank? || row[6] != 'Test' || row[6] != 'Témoin'

        @child_id = row[1].strip
        @group_type = row[6].strip
        send_message
      end
      self
    end

    private

    def initialize_sheets_service
      authorizer = Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: StringIO.new(CREDENTIALS), scope: SCOPE)
      @service = Google::Apis::SheetsV4::SheetsService.new
      @service.authorization = authorizer
    end

    def send_message
      @child = Child.find_by(id: @child_id)
      unless @child
        @errors << "Enfant introuvable : #{row[1].strip}"
        return
      end

      return if @child.tag_list.include?(EVAL_MESSAGE_TAG)

      # message_service = 

      # @errors << "Impossible d'ajouter de tag à l'enfant avec child_id #{@child_id}" unless @child.save
    end
  end
end
