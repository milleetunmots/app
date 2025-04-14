class Child
  class AddEvalTagToChildrenService < ApiGoogle::InitializeSheetsService

    STATUS_MAPPING = {
      completed: ['Répondu'],
      refused: [
        'Non réponse après 3 tentatives KO',
        'Refus étude',
        'Arrêt pour exclusion',
        'Non terminé (parent injoignable)',
        'Rdv sans réponse après 3 tentatives'
      ],
      pending: [
        'Rdv pour y répondre',
        'Incomplet (à terminer)',
        'A rappeler plus tard',
        'Rdv non honoré (à rappeler)'
      ]
    }.freeze
    TAGS = {
      completed: 'Eval25 - validée',
      refused: 'Eval25 - refusée'
    }.freeze

    def initialize
      super
      @sheet_id = ENV['FAMILY_SUPPORTS_SHEET_ID']
      @sheet_name = ENV['FAMILY_SUPPORTS_SHEET_NAME']
    end

    def call
      super
      return self if @errors.any?

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

    def process_child
      find_child
      return unless @child
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
