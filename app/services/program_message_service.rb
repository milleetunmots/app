class ProgramMessageService

  attr_reader :errors

  def initialize(planned_date, planned_hour, recipients, message)
    @planned_timestamp = Time.zone.parse("#{planned_date} #{planned_hour}").to_i
    @recipients = recipients || []
    @message = message
    @tag_ids = []
    @parent_ids = []
    @group_ids = []
    @recipent_datas = []
    @variables = []
    @errors = []
  end

  def call
    check_all_fields_are_present
    return self if @errors.any?

    sort_recip
    find_parent_ids_from_tags
    find_parent_ids_from_groups
    get_all_phone_numbers
    @errors << 'Aucun parent à contacter.' and return self if @recipent_datas.empty?
    get_all_variables if @message.match(/\{(.*?)\}/)
    generate_phone_number_with_datas if @variables.include? 'PRENOM_ENFANT'

    service = SpotHit::SendSmsService.new(@recipent_datas, @planned_timestamp, @message).call
    @errors = service.errors if service.errors.any?
    self
  end

  private

  def get_all_variables
    @variables += @message.scan(/\{(.*?)\}/).transpose[0].uniq
  end

  def generate_phone_number_with_datas
    hash = Hash[@recipent_datas.collect { |item| [item, {}] } ]
    Parent.where(phone_number: @recipent_datas).find_each do |parent|
      hash[parent.phone_number]['PRENOM_ENFANT'] = parent.first_child.first_name || 'votre enfant'
    end
    @recipent_datas = hash
  end

  def check_all_fields_are_present
    @errors << 'Tous les champs doivent être complétés.' if !@planned_timestamp.present? || @recipients.empty? || @message.empty?
  end

  def get_all_phone_numbers
    @recipent_datas += Parent.find(@parent_ids.uniq).pluck(:phone_number)
  end

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
