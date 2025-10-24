class Group::AddDisengagementTagService

  DISENGAGEMENT_STATUSES = ['KO', 'Ne pas appeler', 'Numéro erroné'].freeze

	def initialize(group_id, call_index)
    @group_id = group_id
    # Récupérer les fiches de suivi avec au moins 2 appels avec KO / Ne pas appeler / Numéro erroné
    @child_supports =
      if Group.find(group_id).type_of_support == 'without_calls'
        []
      else
        case call_index
        when 1
          ChildSupport.group_id_in(group_id).with_a_child_in_active_group.
            where('call1_status IN (?, ?, ?)', 'KO', 'Ne pas appeler', 'Numéro erroné').
            select { |child_support| child_support.call0_status.in? DISENGAGEMENT_STATUSES }
        when 2
          ChildSupport.group_id_in(group_id).with_a_child_in_active_group.
            where('call2_status IN (?, ?, ?)', 'KO', 'Ne pas appeler', 'Numéro erroné').
            select { |child_support| child_support.call1_status.in?(DISENGAGEMENT_STATUSES) || child_support.call0_status.in?(DISENGAGEMENT_STATUSES) }
        when 3
          ChildSupport.group_id_in(group_id).with_a_child_in_active_group.
            where('call3_status IN (?, ?, ?)', 'KO', 'Ne pas appeler', 'Numéro erroné').
            select { |child_support| child_support.call2_status.in?(DISENGAGEMENT_STATUSES) || child_support.call1_status.in?(DISENGAGEMENT_STATUSES) || child_support.call0_status.in?(DISENGAGEMENT_STATUSES) }
        else
          []
        end
      end
	end

	def call
    return self if Group.find(@group_id).type_of_support == 'without_calls'

		@child_supports.each do |child_support|
			child_support.tag_list += ['desengage-2appelsKO']
      child_support.save!
    end
		self
	end
end
