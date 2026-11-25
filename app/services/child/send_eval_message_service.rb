class Child
  class SendEvalMessageService < ApiGoogle::InitializeSheetsService

    EVAL_MESSAGE_TAG = 'lien_eval25_envoye'.freeze
    BUNDLE = ["Fin d'accompagnement, étude eval", 'eval_fin_accompagnement'].freeze

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
        next if row[1].blank? || row[6] != 'Test'
        next if row[20].in?(['Appel 1 ok', 'Appel 2 ok', 'Appel 3 ok', 'Ne souhaite pas répondre', 'Numéro erroné'])

        @child_id = row[1].strip
        send_message
      end
      self
    end

    private

    def send_message
      find_child
      return unless @child
      return if @child.tag_list.include?(EVAL_MESSAGE_TAG)

      return report_missing_bundle unless bundle

      message_service = program_message
      if message_service.errors.any?
        @errors << "Impossible d'envoyer le message au parent de l'enfant avec child_id #{@child_id} : #{message_service.errors}"
      else
        @child.tag_list << EVAL_MESSAGE_TAG
        @errors << "Impossible d'ajouter le tag à l'enfant avec l'id #{@child.id}" unless @child.save
      end
    end

    def program_message
      ProgramAutomaticMessageService.new(
        Time.zone.now.strftime('%d-%m-%Y'), Time.zone.now.strftime('%H:%M'), ["child.#{@child.id}"],
        bundle.body1, bundle.rcs_media_id_to_send(1), bundle.redirection_target_id(1), false, nil, nil, %w[active stopped disengaged],
        automatic_message_key: BUNDLE.last, recipient_variables: child_variables
      ).call
    end

    # Lien et prénom de l'enfant traité, pour chacun de ses parents.
    def child_variables
      values = { 'LIEN_ETUDE_EVAL' => Rails.application.routes.url_helpers.eval_form_url(st: @child.security_token), 'PRENOM_ENFANT' => @child.first_name }
      [@child.parent1_id, @child.parent2_id].compact.index_with { values }
    end

    def bundle
      return @bundle if defined?(@bundle)

      @bundle = Media::TextMessagesBundle.find_automatic(name: BUNDLE.first, key: BUNDLE.last)
    end

    def report_missing_bundle
      return if @missing_bundle_reported

      @missing_bundle_reported = true
      @errors << Media::TextMessagesBundle.missing_message(name: BUNDLE.first, key: BUNDLE.last)
    end
  end
end
