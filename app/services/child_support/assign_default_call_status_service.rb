class ChildSupport::AssignDefaultCallStatusService

	def initialize(group_id, call_number)
		@group = Group.find(group_id)
		@call_number = call_number.to_i
	end
  
	def call
		ChildSupport.includes(:children).where(children: { id: @group.children.active_group.map(&:id) }).where("call#{@call_number}_status".to_sym => [nil, '']).uniq.each do |child_support|
			call_status =
				case @call_number
				when 2
					default_call2_status(child_support)
				else
					default_call_status(child_support)
				end
			status_details = "Appel automatiquement passé en statut #{call_status} le #{Time.zone.now.strftime("%d/%m/%Y à %H:%M")}\n\n"
			status_details += child_support.send("call#{@call_number}_status_details") || ''
			child_support.update("call#{@call_number}_status" => call_status, "call#{@call_number}_status_details" => status_details)
		end
		self
	end
  
	private

	def default_call2_status(child_support)
		if child_support.send("call#{@call_number}_notes").blank? && child_support.send("call#{@call_number}_duration").blank? &&
			child_support.current_child.children_support_modules.not_programmed.last&.support_module_id.nil?
			'KO'
		else
			'OK'
		end
	end

	def default_call_status(child_support)
		notes = child_support.send("call#{@call_number}_notes")
		if call_notes_are_blank?(notes) && child_support.send("call#{@call_number}_duration").blank?
			'KO'
		else
			'OK'
		end
	end

	def call_notes_are_blank?(notes)
		return notes.blank? if @call_number != 0

		# remove template from call 0 notes to determine if they are blank
		notes_without_formating = notes&.gsub(/[\n\r\s]/, '')
		notes_without_formating.blank? || notes_without_formating.eql?(I18n.t('child_support.default.call0_notes')&.gsub(/[\n\r\s]/, ''))
	end
end
