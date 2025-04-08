require 'google/apis/sheets_v4'
require 'googleauth'

class Child
  class AddEvalTagToChildrenService

    CREDENTIALS = Base64.decode64(ENV['GOOGLE_CREADENTIALS_JSON']).freeze
    SCOPE = ['https://www.googleapis.com/auth/spreadsheets'].freeze
    STATUS_MAPPING = {
      completed: ['Répondu'],
      refused: [
        'Non réponse après 3 tentatives KO',
        'Refus étude',
        'Arrêt pour exclusion',
        'Non terminé (parent injoignable)'
      ],
      pending: [
        'Rdv pour y répondre',
        'Incomplet (à terminer)',
        'A rappeler plus tard',
        'Rdv non honoré (à rappeler)',
        'Rdv sans réponse après 3 tentatives'
      ]
    }.freeze
    TAGS = {
      completed: 'Eval25 - validée',
      refused: 'Eval25 - refusée'
    }.freeze

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
        next if row[1].blank? || row[24].blank? || (row[0] != 'FALSE' && row[0] != 'TRUE')

        @child_id = row[1].strip
        @response_status = row[24].strip
        process_child
      end
      self
    end

    private

    def initialize_sheets_service
      authorizer = Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: StringIO.new(CREDENTIALS), scope: SCOPE)
      @service = Google::Apis::SheetsV4::SheetsService.new
      @service.authorization = authorizer
    end

    def process_child
      @child = Child.find_by(id: @child_id)
      unless @child
        @errors << "Enfant introuvable : #{row[1].strip}"
        return
      end

      return if @child.tag_list.include?(TAGS[:completed]) || @child.tag_list.include?(TAGS[:refused])

      return unless @child.group_status.in? %w[waiting active paused]

      case status_category
      when :completed
        @child.tag_list << TAGS[:completed]
      when :refused
        @child.tag_list << TAGS[:refused]
      when :pending
        return
      else
        @errors << "Statut inconnu : #{@response_status} pour child_id #{@child_id}"
        return
      end
      @errors << "Impossible d'ajouter de tag à l'enfant avec child_id #{@child_id}" unless @child.save
    end

    def status_category
      if STATUS_MAPPING[:completed].include?(@response_status)
        :completed
      elsif STATUS_MAPPING[:refused].include?(@response_status)
        :refused
      elsif STATUS_MAPPING[:pending].include?(@response_status)
        :pending
      else
        :unknown
      end
    end
  end
end
