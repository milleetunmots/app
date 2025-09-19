class Group::AddDisengagementTagService
	attr_reader

	def initialize(group_id, call_index)
    # Calculer le nombre d'appels avec KO ou ne pas appeler et recuperer les fiches de suivi avec plus de 2
    @child_supports =
      case call_index
      when 1
        ChildSupport.group_id_in(group_id).with_a_child_in_active_group.
          where('call1_status IN (?, ?)', 'KO', 'Ne pas appeler').
          select { |child_support| child_support.call0_status.in? ['KO', 'Ne pas appeler'] }
      when 2
        ChildSupport.group_id_in(group_id).with_a_child_in_active_group.
          where('call2_status IN (?, ?)', 'KO', 'Ne pas appeler').
          select { |child| child.call1_status.in?(['KO', 'Ne pas appeler']) || child.call0_status.in?(['KO', 'Ne pas appeler']) }
      when 3
        ChildSupport.group_id_in(group_id).with_a_child_in_active_group.
          where('call3_status IN (?, ?)', 'KO', 'Ne pas appeler').
          select { |child| child.call2_status.in?(['KO', 'Ne pas appeler']) || child.call1_status.in?(['KO', 'Ne pas appeler']) || child.call0_status.in?(['KO', 'Ne pas appeler']) }
      else
        []
      end
	end

	def call
		@child_supports.each do |child_support|
			child_support.tag_list.add('desengage-2appelsKO')
      child_support.save!
    end
		self
	end
end
