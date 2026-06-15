class ChildSupport::CallerRestartSupportService

	attr :error

	UNREACHABLE_NUMBER_REASON = 'unreachable_number'.freeze

	def initialize(supporter_id, child_support_id, reason, details)
		@supporter = AdminUser.find(supporter_id)
		@child_support = ChildSupport.find(child_support_id)
		@reason = reason
		@details = details
		@date = Time.zone.now
		@error = nil
	end

	def call
		ActiveRecord::Base.transaction do
      add_restart_support_informations
      if unreachable_number_restart?
        restart_support_for_unreachable_number
      else
        restart_support
        add_tag
      end
		end
		self
	end

	private

	def unreachable_number_restart?
		@reason.include?(UNREACHABLE_NUMBER_REASON)
	end

	def add_restart_support_informations
		@child_support.restart_support_caller_id = @supporter.id
		@child_support.restart_support_date = @date
    @child_support.restart_support_details = @reason.join('; ')
    @child_support.restart_support_details += " : #{@details}" if @details.present?
    @error = "Les informations n'ont pas pu être ajoutée à la fiche de suivie" unless @child_support.save
		raise ActiveRecord::Rollback unless @error.nil?
	end

	def restart_support
		@child_support.children.each do |child|
      next unless child.group_status == 'disengaged'

      child.group_status = 'active'
      child.group_end = nil
			@error = "L'accompagnement de #{child.first_name} n'a pas pu être repris" unless child.save
			raise ActiveRecord::Rollback unless @error.nil?
		end
		@child_support.important_information = "#{@child_support.important_information}\nAccompagnement relancé le #{@date.strftime('%d/%m/%Y')}"
		@child_support.save
	end

	def restart_support_for_unreachable_number
		reactivated_any = false
		@child_support.children.each do |child|
			next unless child.group_status == 'stopped'
			next unless child.group.present? && child.group.is_not_ended?

			child.group_status = 'active'
			child.group_end = nil
			if child.contact_parent1_unset_for_unassigned_number
				child.should_contact_parent1 = true
				child.contact_parent1_unset_for_unassigned_number = false
			end
			if child.contact_parent2_unset_for_unassigned_number
				child.should_contact_parent2 = true
				child.contact_parent2_unset_for_unassigned_number = false
			end
			@error = "L'accompagnement de #{child.first_name} n'a pas pu être repris" unless child.save
			raise ActiveRecord::Rollback unless @error.nil?
			reactivated_any = true
		end

		unless reactivated_any
			@error = "Aucun enfant n'a pu être réactivé (cohorte terminée ou enfant non arrêté pour numéro erroné)"
			raise ActiveRecord::Rollback
		end

		@child_support.important_information = "Accompagnement redémarré le #{@date.strftime('%d/%m/%Y')} suite à la mise à jour du numéro à contacter.\n" + @child_support.important_information.to_s
		@child_support.support_stopped_for_unassigned_number_at = nil
		@child_support.save
	end

	def add_tag
		tag = Tag.find_or_create_by(name: 'accompagnement redemarre', is_visible_by_callers_and_animators: true)
		@child_support.tag_list += [tag.name]
		@error = "Le tag n'a pas pu être ajouté à la fiche de suivi" unless @child_support.save
		raise ActiveRecord::Rollback unless @error.nil?
	end
end
