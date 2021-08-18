class ProgramMessageService

  attr_reader :errors

  def initialize(planned_date, planned_hour, recipients, message, redirection_target_id = nil)
    @planned_timestamp = Time.zone.parse("#{planned_date} #{planned_hour}").to_i
    @recipients = recipients || []
    @message = message
    @tag_ids = []
    @parent_ids = []
    @redirection_target = RedirectionTarget.find(redirection_target_id) if redirection_target_id
    @group_ids = []
    @recipient_data = []
    @variables = []
    @errors = []
  end

  def call
    check_all_fields_are_present
    return self if @errors.any?

    get_all_variables if @message.match(/\{(.*?)\}/)
    return self if @errors.any?

    sort_recipients
    find_parent_ids_from_tags
    find_parent_ids_from_groups
    get_all_phone_numbers
    @errors << "Aucun parent à contacter." and return self if @recipient_data.empty?

    generate_phone_number_from_data if @redirection_target || @variables.include?("PRENOM_ENFANT")
    return self if @errors.any?

    @message += " {URL}" if @redirection_target && !@variables.include?("URL")

    service = SpotHit::SendSmsService.new(@recipient_data, @planned_timestamp, @message).call
    @errors = service.errors if service.errors.any?
    self
  end

  private

  def get_all_variables
    @variables += @message.scan(/\{(.*?)\}/).transpose[0].uniq

    @errors << "Veuillez choisir un lien cible." if @redirection_target.nil? && @variables.include?("URL")
  end

  def generate_phone_number_from_data
    hash = Hash[@recipient_data.collect { |item| [item, {}] }]
    Parent.where(phone_number: @recipient_data).find_each do |parent|
      hash[parent.phone_number]["PRENOM_ENFANT"] = (parent.first_child.first_name || "votre enfant")
      if @redirection_target
        redirection_url = parent.redirection_urls.find_by(child_id: parent.first_child.id, parent_id:parent.id, redirection_target_id: @redirection_target.id)
        if redirection_url.nil?
          redirection_url = RedirectionUrl.new(
            redirection_target_id: @redirection_target.id,
            parent_id: parent.id,
            child_id: parent.first_child.id
          )
          if redirection_url.save
            hash[parent.phone_number]["URL"] = redirection_url.decorate.visit_url
          else
            @errors << "Problème(s) avec l'url courte." and return
          end
        else
          hash[parent.phone_number]["URL"] = redirection_url.decorate.visit_url
        end
      end
    end
    @recipient_data = hash
  end

  def check_all_fields_are_present
    @errors << "Tous les champs doivent être complétés." if !@planned_timestamp.present? || @recipients.empty? || @message.empty?
  end

  def get_all_phone_numbers
    @recipient_data += Parent.find(@parent_ids.uniq).pluck(:phone_number)
  end

  def sort_recipients
    @recipients.each do |recipient_id|
      if recipient_id.include? "parent."
        @parent_ids << recipient_id[/\d+/].to_i
      elsif recipient_id.include? "tag."
        @tag_ids << recipient_id[/\d+/].to_i
      elsif recipient_id.include? "group."
        @group_ids << recipient_id[/\d+/].to_i
      end
    end
  end

  def find_parent_ids_from_tags
    @tag_ids.each do |tag_id|
      # taggable_id = id of the parent in our case
      @parent_ids += Tagging.by_taggable_type("Parent").by_tag_id(tag_id).pluck(:taggable_id)
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
