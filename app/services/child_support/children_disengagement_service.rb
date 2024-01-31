class ChildSupport::ChildrenDisengagementService

  def initialize(group)
    @group = group
  end

  def call
    ChildSupport.includes(:children).where(children: { id: @group.children.map(&:id) }).tagged_with('estimé-desengagé').uniq.each do |child_support|
      if child_support.module4_chosen_by_parents
        child_support.tag_list = child_support.tag_list.map { |tag| tag == 'estimé-desengagé' ? 'estimé-desengagé-conservé' : tag }
      else
        child_support.tag_list = child_support.tag_list.map { |tag| tag == 'estimé-desengagé' ? 'desengagé' : tag }
        child_support.children.update(group_status: 'disengaged', group_end: Time.zone.today)
      end
      child_support.save
    end
  end
end
