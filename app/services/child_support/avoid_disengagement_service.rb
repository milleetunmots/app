class ChildSupport::AvoidDisengagementService

	attr :error

	def initialize(supporter_id, child_support_id, reason, details, call_index)
		@supporter = AdminUser.find(supporter_id)
		@child_support = ChildSupport.find(child_support_id)
		@reason = reason
		@details = details
    @call_index = call_index
		@date = Time.zone.now
    @tag = Tag.find_or_create_by(name: 'desengagement empeche', is_visible_by_callers_and_animators: true)
  end

	def call
		ActiveRecord::Base.transaction do
      @child_support.update("call#{@call_index}_avoid_disengagement_date" => @date)
      @child_support.update("call#{@call_index}_avoid_disengagement_details" => @reason.join('; '))
      @child_support.important_information = "#{@child_support.important_information}\nDésengagement empêché le #{@date.strftime('%d/%m/%Y')}"
      @child_support.tag_list += [@tag.name]
      unless @child_support.save
        @error = "Les informations n'ont pas pu être ajoutée à la fiche de suivie"
        raise ActiveRecord::Rollback
      end
    end
		self
	end
end
