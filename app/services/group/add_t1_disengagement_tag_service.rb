class Group::AddT1DisengagementTagService
	attr_reader

	def initialize(group_id)
		@child_supports = ChildSupport.group_id_in(group_id).with_a_child_in_active_group.
																	 where('call0_status IN (?, ?)', 'KO', 'Ne pas appeler').
																	 where('call1_status IN (?, ?)', 'KO', 'Ne pas appeler').
																	 where('call2_status IN (?, ?)', 'KO', 'Ne pas appeler')
	end
  
	def call
		@child_supports.each do |child_support|
			child_support.tag_list.add('estimées-désengagées-T1')
      child_support.save!
		end
		self
	end
end
