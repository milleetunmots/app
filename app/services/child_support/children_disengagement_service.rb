class ChildSupport::ChildrenDisengagementService

  def initialize(group_id)
    @group = Group.find(group_id)
  end

  def call
    ChildSupport.includes(:children).where(children: { id: @group.children.map(&:id) }).tagged_with('estime-desengage-t2').uniq.each do |child_support|
      if module4_chosen(child_support, @group.id)
        child_support.tag_list = child_support.tag_list.map { |tag| tag == 'estime-desengage-t2' ? 'estime-desengage-conserve-t2' : tag }
      else
        child_support.tag_list = child_support.tag_list.map { |tag| tag == 'estime-desengage-t2' ? 'desengage-t2' : tag }
        child_support.children.update(group_status: 'disengaged', group_end: Time.zone.today)
      end
      child_support.save
    end

    ChildSupport.includes(:children).where(children: { id: @group.children.map(&:id) }).tagged_with('estime-desengage-t1').uniq.each do |child_support|
      if module2_chosen(child_support)
        child_support.tag_list = child_support.tag_list.map { |tag| tag == 'estime-desengage-t1' ? 'estime-desengage-conserve-t1' : tag }
      else
        child_support.tag_list = child_support.tag_list.map { |tag| tag == 'estime-desengage-t1' ? 'desengage-t1' : tag }
        child_support.children.update(group_status: 'disengaged', group_end: Time.zone.today)
      end
      child_support.save
    end
  end

  private

  def module4_chosen(child_support, group_id)
    if group_id == ENV['JUNE_GROUP_ID'].to_i
      child_support.module6_chosen_by_parents
    else
      child_support.module4_chosen_by_parents
    end
  end

  def module2_chosen(child_support)
    child_support.module2_chosen_by_parents
  end
end
