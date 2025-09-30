class Group::AddDisengagementTagService
	attr_reader

  DISENGAGEMENT_STATUSES = ['KO', 'Ne pas appeler', 'Numéro erroné'].freeze

	def initialize(group_id, call_index)
    # Récupérer les fiches de suivi avec au moins 2 appels avec KO / Ne pas appeler / Numéro erroné
    @child_supports =
      case call_index
      when 1
        ChildSupport.group_id_in(group_id).with_a_child_in_active_group.
          where('call1_status IN (?, ?, ?)', 'KO', 'Ne pas appeler', 'Numéro erroné').
          select { |child_support| child_support.call0_status.in? DISENGAGEMENT_STATUSES }
      when 2
        ChildSupport.group_id_in(group_id).with_a_child_in_active_group.
          where('call2_status IN (?, ?, ?)', 'KO', 'Ne pas appeler', 'Numéro erroné').
          select { |child| child.call1_status.in?(DISENGAGEMENT_STATUSES) || child.call0_status.in?(DISENGAGEMENT_STATUSES) }
      when 3
        ChildSupport.group_id_in(group_id).with_a_child_in_active_group.
          where('call3_status IN (?, ?, ?)', 'KO', 'Ne pas appeler', 'Numéro erroné').
          select { |child| child.call2_status.in?(DISENGAGEMENT_STATUSES) || child.call1_status.in?(DISENGAGEMENT_STATUSES) || child.call0_status.in?(DISENGAGEMENT_STATUSES) }
      else
        []
      end
	end

	def call
    return self if @group.started_at < Date.parse(ENV['OCTOBER25A_GROUP_STARTED_AT'])

		@child_supports.each do |child_support|
			child_support.tag_list.add('desengage-2appelsKO')
      child_support.save!
    end
		self
	end
end
