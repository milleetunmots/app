class Child
  class AddEvalTagToChildrenService < ApiGoogle::InitializeSheetsService

    STATUS_MAPPING = {
      completed: ['Répondu'],
      refused: [
        'Refus étude',
        'Arrêt pour exclusion',
        'Non terminé (parent injoignable)'
      ],
      pending: [
        'Rdv pour y répondre',
        'Incomplet (à terminer)',
        'A rappeler plus tard',
        'Rdv non honoré (à rappeler)'
      ],
      three_attempts: [
        'Non réponse après 3 tentatives KO',
        'Rdv sans réponse après 3 tentatives'
      ]
    }.freeze
    CONTROL_GROUP_RESPONSES = [
      'Répondu',
      'Arrêt pour exclusion',
      'Refus étude'
    ].freeze
    TAGS = {
      completed: 'Eval25 - validée',
      refused: 'Eval25 - refusée',
      three_attempts: 'Eval25 - 3 tentatives',
      include_in_group: 'Eval - OK pour inclure dans une cohorte',
      exclude_from_group: 'Eval - ne pas inclure dans une cohorte'
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
        child_id = row[1].is_a?(Integer) ? row[1] : row[1]&.strip
        group = row[6]&.strip
        response_status = row[24]&.strip
        next if child_id.blank? || group.blank? || response_status.blank? || (row[0] != 'FALSE' && row[0] != 'TRUE')

        @child_id = child_id
        @response_status = response_status
        @group = group
        find_child
        next unless @child

        add_eval_tags_to_child
        add_eval_tags_to_control_group_siblings
      end
      self
    end

    private

    def add_eval_tags_to_child
      return if @child.tag_list.include?(TAGS[:completed]) || @child.tag_list.include?(TAGS[:refused]) || @child.tag_list.include?(TAGS[:three_attempts])
      return unless @child.group_status.in? %w[waiting active paused]

      case status_category
      when :completed
        @child.tag_list.add(TAGS[:completed])
      when :refused
        @child.tag_list.add(TAGS[:refused])
      when :three_attempts
        @child.tag_list.add(TAGS[:three_attempts])
      when :pending
        return
      else
        @errors << "Statut inconnu : #{@response_status} pour child_id #{@child_id}"
        return
      end
      @errors << "Impossible d'ajouter de tag à l'enfant avec child_id #{@child_id}" unless @child.save
    end

    def add_eval_tags_to_control_group_siblings
      return unless @group == 'Témoin'

      if CONTROL_GROUP_RESPONSES.include?(@response_status)
        @child.siblings.each do |child|
          child.tag_list.add(TAGS[:include_in_group])
          child.tag_list.remove(TAGS[:exclude_from_group])
          @errors << "Impossible d'ajouter de tag à l'enfant avec child_id #{child.id}" unless child.save
        end
      else
        @child.siblings.each do |child|
          child.tag_list.add(TAGS[:exclude_from_group])
          child.tag_list.remove(TAGS[:include_in_group])
          @errors << "Impossible d'ajouter de tag à l'enfant avec child_id #{child.id}" unless child.save
        end
      end
    end

    def status_category
      if STATUS_MAPPING[:completed].include?(@response_status)
        :completed
      elsif STATUS_MAPPING[:refused].include?(@response_status)
        :refused
      elsif STATUS_MAPPING[:pending].include?(@response_status)
        :pending
      elsif STATUS_MAPPING[:three_attempts].include?(@response_status)
        :three_attempts
      else
        :unknown
      end
    end
  end
end
