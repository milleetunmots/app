class ChildSupport::CallerStopSupportService

	PROGRAM_SMS = '1001mots: Suite à votre demande, votre accompagnement prend fin. Vous ne recevrez plus ni appels, ni SMS, ni livres. Nous vous transmettons tout de même cette page {URL} avec des conseils pour développer le langage de {PRENOM_ENFANT}. Pour des raisons techniques, vous allez recevoir encore les SMS pendant quelques semaines, vous pouvez répondre STOP pour arrêter au plus vite. Bonne continuation à vous :) !'.freeze
	POPI_SMS = '1001mots: Votre accompagnement s’arrête ici. Nous vous invitons cependant à consulter cette page {URL} qui comporte des ressources et des recommandations pour vous aider dans l’éveil langagier de votre enfant. Pour des raisons techniques, vous allez recevoir encore des sms pendant quelques semaines, répondez STOP si vous voulez les arrêter avant. Merci pour votre compréhension et belle journée à vous.'.freeze
	PROFESSIONAL_SMS = '1001mots: Merci de l’intérêt que vous portez à notre accompagnement ! Celui-ci est réservé aux familles bénéficiaires, mais si vous souhaitez le tester, vous pouvez entrer en contact avec nos équipes via le formulaire ci-dessous. Merci pour votre compréhension et belle journée à vous {URL}'.freeze
	PROBLEMATIC_CASE_SMS = '1001mots: Votre accompagnement s’arrête ici. Pour des raisons techniques, vous allez recevoir encore des sms pendant quelques semaines, répondez STOP si vous voulez les arrêter avant.'.freeze
	RENUNCIATION_SMS = "Si vous ne voulez pas recevoir d'appels de notre part, nous devons arrêter l'ensemble de votre accompagnement (SMS, livres et appels). Cliquez sur ce lien pour confirmer que vous souhaitez arrêter l'accompagnement 1001mots. Merci pour votre compréhension et belle journée à vous.".freeze
	SMS_LINK = 'https://www.notion.so/1001mots-ne-peut-plus-vous-accompagner-35ec2e040f3d47b99a94028c51c7a3e4'.freeze
	PROFESSIONAL_SMS_LINK = 'https://airtable.com/apppjysEG5cvcWLX1/shrfPvKCa0MxSfiHk'.freeze
	VARIABLES = {
			program: { tag: 'arrêt appelante - programme', sms: PROGRAM_SMS, url: SMS_LINK, motive: 'refuse certaines parties du programme' },
			popi: { tag: 'arrêt appelante - popi', sms: POPI_SMS, url: SMS_LINK, motive: 'famille popi' },
			professional: { tag: 'arrêt appelante - pro de santé', sms: PROFESSIONAL_SMS, url: PROFESSIONAL_SMS_LINK, motive: 'pro de santé' },
			problematic_case: { tag: 'arrêt appelante - problèmes', sms: PROBLEMATIC_CASE_SMS, url: nil, motive: 'problèmes' },
			renunciation: { tag: 'arrêt appelante - programme', sms: RENUNCIATION_SMS, url: nil, motive: nil }
		}.freeze

	attr :error

	def initialize(supporter_id, child_support_id, reason, details)
		@supporter = AdminUser.find(supporter_id)
		@child_support = ChildSupport.find(child_support_id)
		@reason = reason
		@details = details
		@date = DateTime.now
		@error = nil
	end

	def call
		ActiveRecord::Base.transaction do
			add_stop_support_informations
			stop_support
			add_tag
			send_message
		end
		self
	end

	private

	def add_stop_support_informations
		@child_support.stop_support_caller_id = @supporter.id
		@child_support.stop_support_date = DateTime.now
		@child_support.stop_support_details = @details
		@error = "Les informations n'ont pas pu être ajoutée à la fiche de suivie" unless @child_support.save
		raise @error unless @error.nil?
	end

	def stop_support
		return if @reason == 'renunciation'

		@child_support.children.each do |child|
			child.group_status = 'stopped'
			child.group_end = Time.zone.today
			@error = "L'accompagnement de #{child.name} n'a pas pu être arrêtée" unless child.save
			raise @error unless @error.nil?
		end
		@child_support.important_information = "#{@child_support.important_information}\Accompagnement arreté le #{@child_support.stop_support_date.strftime('%d/%m/%Y')} pour le motif '#{VARIABLES[@reason.to_sym][:motive]}' à la demande de #{@supporter.name}"
		@child_support.save
	end

	def add_tag
		return if @reason == 'renunciation'

		@child_support.tag_list.add(VARIABLES[@reason.to_sym][:tag])
		@child_support.save!
		@error = "Le tag n'a pas pu être ajouté à la fiche de suivi" unless @child_support.save
		raise @error unless @error.nil?
	end

	def create_stop_support_link_for_renunciation
		return unless @reason == 'renunciation'

		@url = Rails.application.routes.url_helpers.confirm_end_support_url(
        child_support_id: @child_support.id,
        parent1_sc: @child_support.parent1.security_code
      )
		@message = "#{@message} #{@url}"
	end

	def send_message
		return unless @child_support.should_contact_parent1 || @child_support.should_contact_parent2

		@error = "L'URL du message n'a pas pu être récupéré" if VARIABLES[@reason.to_sym][:url].present? && redirection_target_id.nil?
		raise @error unless @error.nil?

		@message = VARIABLES[@reason.to_sym][:sms]
		create_stop_support_link_for_renunciation
		program_message_service = ProgramMessageService.new(
			@date.strftime('%Y-%m-%d'),
			@date.strftime('%H:%M'),
			recipients,
			@message,
			nil,
			redirection_target_id
		).call
		@error = program_message_service.errors.join("\n") if program_message_service.errors.any?
		raise @error unless @error.nil?
	end

	def redirection_target_id
		return nil if VARIABLES[@reason.to_sym][:url].nil?

		form = Media::Form.find_by(url: VARIABLES[@reason.to_sym][:url])
		if form
			form.create_redirection_target unless form.redirection_target
			form.redirection_target.id
		else
			new_form = Media::Form.create(name: 'Arrêt appelante - lien 1', url: VARIABLES[@reason.to_sym][:url])
			new_form.redirection_target.id
		end
	end

	def recipients
		recipients = ["parent.#{@child_support.parent1.id}"]
		recipients << "parent.#{@child_support.parent2.id}" if @child_support.parent2
		recipients
	end
end
