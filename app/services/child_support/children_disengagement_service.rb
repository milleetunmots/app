class ChildSupport::ChildrenDisengagementService

  def initialize(group_id)
    @group = Group.find(group_id)
  end

  def call
    ChildSupport.includes(:children).where(children: { id: @group.children.map(&:id) }).tagged_with('desengage-2appelsKO').uniq.each do |child_support|
      child_support.children.update(group_status: 'disengaged', group_end: Time.zone.today)
      child_support.save
    end
  end
end
