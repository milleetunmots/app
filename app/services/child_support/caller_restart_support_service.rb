class ChildSupport::CallerRestartSupportService

	attr :error

	def initialize(supporter_id, child_support_id, reason, details)
		@supporter = AdminUser.find(supporter_id)
		@child_support = ChildSupport.find(child_support_id)
		@reason = reason
		@details = details
		@date = Time.zone.now
		@error = nil
    @tag = Tag.find_or_create_by(name: 'accompagnement redemarre', is_visible_by_callers_and_animators: true)
  end

	def call
		ActiveRecord::Base.transaction do
      add_restart_support_informations
      restart_support
			add_tag
		end
		self
	end

	private

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

	def add_tag
		@child_support.tag_list += [@tag.name]
		@child_support.save
		@error = "Le tag n'a pas pu être ajouté à la fiche de suivi" unless @child_support.save
		raise ActiveRecord::Rollback unless @error.nil?
	end
end
