class Child
  class SendEvalMessageService < ApiGoogle::InitializeSheetsService

    EVAL_MESSAGE_TAG = 'lien_eval25_envoye'.freeze
    EVAL_MESSAGE = "1001mots : L'accompagnement de {PRENOM_ENFANT} est maintenant terminé. Vous avez AIMÉ les livres et les conseils ? Alors vous pouvez nous AIDER à votre tour : PARTICIPEZ à notre grande ETUDE sur le langage des bébés ! Cliquez ici pour en savoir plus : {typeform_link}".freeze

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
        next if row[1].blank? || row[6] != 'Test' || !row[20].in?(['Appel 1 ok', 'Appel 2 ok', 'Appel 3 ok', 'Ne souhaite pas répondre', 'Numéro erroné'])

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

      message = EVAL_MESSAGE.gsub('{typeform_link}', Rails.application.routes.url_helpers.eval_form_url(st: @child.security_token))


      message_service = ProgramMessageService.new(
        Time.zone.now.strftime('%d-%m-%Y'),
        Time.zone.now.strftime('%H:%M'),
        ["child.#{@child.id}"],
        message,
        nil,
        nil,
        false,
        nil,
        nil,
        ['active', 'stopped']
      ).new.call
      if message_service.errors.any?
        @errors << "Impossible d'envoyer le message au parent de l'enfant avec child_id #{@child_id} : #{message_service.errors}"
      else
        @child.tag_list << EVAL_MESSAGE_TAG
        @errors << "Impossible d'ajouter le tag à l'enfant avec l'id #{@child.id}" unless @child.save
      end
    end
  end
end
