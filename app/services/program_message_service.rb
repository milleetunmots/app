class ProgramMessageService

  attr_reader :errors

  def initialize(planned_date, planned_hour, recipients, message, url = nil)
    @planned_timestamp = Time.zone.parse("#{planned_date} #{planned_hour}").to_i
    @recipients = recipients || []
    @message = message
    @tag_ids = []
    @parent_ids = []
    @url = RedirectionTarget.find(url) if url
    @group_ids = []
    @recipent_datas = []
    @variables = []
    @errors = []
  end

  def call
    check_all_fields_are_present
    return self if @errors.any?
    get_all_variables if @message.match(/\{(.*?)\}/)
    
    @errors << 'Veuillez choisir un lien cible.' and return self if @url.nil? and @variables.include? 'URL'
    sort_recipients
    find_parent_ids_from_tags
    find_parent_ids_from_groups
    get_all_phone_numbers

    @errors << 'Aucun parent à contacter.' and return self if @recipent_datas.empty?
    generate_phone_number_with_datas if @url or @variables.include? 'PRENOM_ENFANT'
    @message += " {URL}" if @url and !@variables.include? 'URL'
    
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
      if parent.first_child.first_name
        hash[parent.phone_number]['PRENOM_ENFANT'] = parent.first_child.first_name
      else
        hash[parent.phone_number]['PRENOM_ENFANT'] = 'votre enfant'
      end
      if @url
        short_url = RedirectionUrl.new(
          redirection_target_id: @url.id,
          parent_id: parent.id,
          child_id: parent.first_child.id
        )
        if short_url.save
          hash[parent.phone_number]['URL'] = short_url.decorate.visit_url
        else
          @errors << 'Problème(s) avec l\'url courte.' and return
        end
      end
    end
    @recipent_datas = hash
  end

  def check_all_fields_are_present
    @errors << 'Tous les champs doivent être complétés.' if !@planned_timestamp.present? || @recipients.empty? || @message.empty?
  end

  def get_all_phone_numbers
    @recipent_datas += Parent.find(@parent_ids.uniq).pluck(:phone_number)
  end

  def sort_recipients
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
