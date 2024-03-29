class ChildSupport::ChildrenDisengagementService

  def initialize(group)
    @group = group
  end

  def call
    ChildSupport.includes(:children).where(children: { id: @group.children.map(&:id) }).tagged_with('estimé-desengagé').uniq.each do |child_support|
      if module4_chosen(child_support, @group.id)
        child_support.tag_list = child_support.tag_list.map { |tag| tag == 'estimé-desengagé' ? 'estimé-desengagé-conservé' : tag }
      else
        child_support.tag_list = child_support.tag_list.map { |tag| tag == 'estimé-desengagé' ? 'desengagé' : tag }
        child_support.children.update(group_status: 'disengaged', group_end: Time.zone.today)
      end
      child_support.save
    end

    ChildSupport.includes(:children).where(children: { id: @group.children.map(&:id) }).tagged_with('estimées-désengagées-T1').uniq.each do |child_support|
      if module2_chosen(child_support)
        child_support.tag_list = child_support.tag_list.map { |tag| tag == 'estimées-désengagées-T1' ? 'estimées-désengagées-T1-conservées' : tag }
      else
        child_support.tag_list = child_support.tag_list.map { |tag| tag == 'estimées-désengagées-T1' ? 'désengagées-T1' : tag }
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
