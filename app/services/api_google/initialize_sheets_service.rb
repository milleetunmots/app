require 'google/apis/sheets_v4'
require 'googleauth'

class ApiGoogle::InitializeSheetsService

  CREDENTIALS = Base64.decode64(ENV['GOOGLE_CREADENTIALS_JSON']).freeze
  SCOPE = ['https://www.googleapis.com/auth/spreadsheets'].freeze

  attr_reader :errors

  def initialize
    @errors = []
  end

  def call
    initialize_sheets
    @response = @service.get_spreadsheet_values(@sheet_id, @sheet_name)
    @errors << 'Aucune donnée trouvée' if @response.values.empty?
  end

  private

  def initialize_sheets
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: StringIO.new(CREDENTIALS), scope: SCOPE)
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.authorization = authorizer
  end

  def find_child
    @child = Child.find_by(id: @child_id)
    @errors << "Enfant introuvable : #{row[1].strip}" unless @child
  end
end
