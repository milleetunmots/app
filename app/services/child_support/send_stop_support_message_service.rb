class ChildSupport::SendStopSupportMessageService

	SMS = "Si vous ne voulez pas être appelé, nous devons arrêter l'ensemble de votre accompagnement (SMS, livres, appels). Cliquez sur ce lien pour confirmer que vous souhaitez arrêter 1001mots".freeze

	attr :error

	def initialize(child_support_id)
		@child_support = ChildSupport.find(child_support_id)
		@date = DateTime.now
		@error = nil
	end

	def call
		create_stop_support_link
		send_message
		self
	end

	private

	def create_stop_support_link
		@url = Rails.application.routes.url_helpers.confirm_end_support_url(
        child_support_id: @child_support.id,
        parent1_sc: @child_support.parent1.security_code
      )
		@message = "#{SMS} #{@url}"
	end

	def send_message
		program_message_service = ProgramMessageService.new(
			@date.strftime('%Y-%m-%d'),
			@date.strftime('%H:%M'),
			recipients,
			@message
		).call
		@error = program_message_service.errors.join("\n") if program_message_service.errors.any?
		raise @error unless @error.nil?
	end

	def recipients
		recipients = ["parent.#{@child_support.parent1.id}"]
		recipients << "parent.#{@child_support.parent2.id}" if @child_support.parent2
		recipients
	end
end
