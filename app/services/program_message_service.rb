class ProgramMessageService
  def initialize(planned_date, planned_hour, recipients, message)
    @date_sent = Time.parse("#{planned_date} #{planned_hour}").to_i
    @recipients = recipients
    @message = message
    @tag_ids = []
    @parent_ids = []
    @group_ids = []
  end

  def call
    sort_recip
    find_parent_ids_from_tags
    find_parent_ids_from_groups
    @parent_ids.uniq
  end

  private

  def sort_recip

    @recipients.each do |recipient_id|
      if recipient_id.include? 'parent.'
        @parent_ids << recipient_id[/\d+/].to_i
      elsif recipient_id.include? 'tag.'
        @tag_ids << recipient_id[/\d+/].to_i
      elsif recipient_id.include? 'group.'
        @group_ids << recipient_id[/\d+/].to_i
      end
    end
  end

  def find_parent_ids_from_tags
    @tag_ids.each do |tag_id|
      # taggable_id = id of the parent in our case
      @parent_ids += Tagging.by_taggable_type('Parent').by_tag_id(tag_id).pluck(:taggable_id)
    end
  end

  def find_parent_ids_from_groups
    Group.includes(:children).where(id: @group_ids).find_each do |group|
      group.children.each do |child|
        @parent_ids << child.parent1_id if child.parent1_id && child.should_contact_parent1
        @parent_ids << child.parent2_id if child.parent2_id && child.should_contact_parent2
      end
    end
  end

end
