class ProgramMessageService

  attr_reader :errors

  def initialize(planned_date, planned_hour, recipients, message, file = nil, redirection_target_id = nil, quit_message = false)
    @planned_timestamp = Time.zone.parse("#{planned_date} #{planned_hour}").to_i
    @recipients = recipients || []
    @message = message
    @file = file
    @tag_ids = []
    @parent_ids = []
    @redirection_target = RedirectionTarget.find(redirection_target_id) if redirection_target_id
    @group_ids = []
    @recipient_data = []
    @variables = []
    @child_ids = []
    @quit_message = quit_message
    @event_params = {}
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
    find_parent_ids_from_children

    @errors << "Aucun parent à contacter." and return self if @parent_ids.empty?

    format_data_for_spot_hit
    return self if @errors.any?

    @message += " {URL}" if @redirection_target && !@variables.include?("URL")

    service = if @file.nil?
      SpotHit::SendSmsService.new(@recipient_data, @planned_timestamp, @message, event_params: @event_params).call
    else
      SpotHit::SendMmsService.new(@recipient_data, @planned_timestamp, @message, file: @file, event_params: @event_params).call
    end

    if service.errors.any?
      @errors = service.errors
    else
      if @url
        @url.build_redirection_url_sent(occurred_at: Time.now)
        @url.save!
      end
    end
    self
  end

  protected

  def get_all_variables
    @variables += @message.scan(/\{(.*?)\}/).transpose[0].uniq

    @errors << "Veuillez choisir un lien cible." if @redirection_target.nil? && @variables.include?("URL")
  end

  def format_data_for_spot_hit
    # we need to format phone_numbers as hash inn order to include variables
    if @redirection_target || @variables.include?("PRENOM_ENFANT")
      @recipient_data = {}

      Parent.where(id: @parent_ids).find_each do |parent|
        @recipient_data[parent.id.to_s] = {}

        @recipient_data[parent.id.to_s]["PRENOM_ENFANT"] = parent.first_child&.first_name || "votre enfant"

        if @redirection_target && parent.first_child.present?
          @recipient_data[parent.id.to_s]["URL"] = redirection_url_for_a_parent(parent)&.decorate&.visit_url

          @url = RedirectionUrl.where(redirection_target: @redirection_target, parent: parent).first
        end
      end
    elsif @quit_message
      @recipient_data = {}
      @child_ids.each do |child_id|
        child = Child.find(child_id)
        @recipient_data[child.parent1_id.to_s] = {}
        @recipient_data[child.parent1_id.to_s]["QUIT_LINK"] = Rails.application.routes.url_helpers.edit_child_url(
          id: child_id,
          security_code: child.security_code
        )

        @event_params[child.parent1_id.to_s] = { quit_group_child_id: child_id }

        if child.parent2
          @recipient_data[child.parent2_id&.to_s]["QUIT_LINK"] = Rails.application.routes.url_helpers.edit_child_url(
            id: child_id,
            security_code: child.security_code
          )
          @event_params[child.parent2_id.to_s] = { quit_group_child_id: child_id }
        end
      end
    else
      # If no variables, we can just sent an array of parent ids
      @recipient_data = @parent_ids
    end
  end

  def redirection_url_for_a_parent(parent)
    redirection_url = parent.redirection_urls.find_by(child_id: parent.first_child.id, parent_id: parent.id, redirection_target_id: @redirection_target.id)

    if redirection_url.nil?
      redirection_url = RedirectionUrl.new(
        redirection_target_id: @redirection_target.id,
        parent_id: parent.id,
        child_id: parent.first_child.id
      )
      unless redirection_url.save
        @errors << "Problème(s) avec l'url courte."
      end
    end

    redirection_url
  end

  def check_all_fields_are_present
    @errors << "Tous les champs doivent être complétés." if !@planned_timestamp.present? || @recipients.empty? || @message.empty?
  end

  def sort_recipients
    @recipients.each do |recipient_id|
      if recipient_id.include? "parent."
        @parent_ids << recipient_id[/\d+/].to_i
      elsif recipient_id.include? "tag."
        @tag_ids << recipient_id[/\d+/].to_i
      elsif recipient_id.include? "group."
        @group_ids << recipient_id[/\d+/].to_i
      elsif recipient_id.include? "child."
        @child_ids << recipient_id[/\d+/].to_i
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
        next unless child.group_status == "active"

        @parent_ids << child.parent1_id if child.parent1_id && child.should_contact_parent1
        @parent_ids << child.parent2_id if child.parent2_id && child.should_contact_parent2
      end
    end
  end

  def find_parent_ids_from_children
    Child.where(id: @child_ids).find_each do |child|

      @parent_ids << child.parent1_id if child.parent1_id && child.should_contact_parent1
      @parent_ids << child.parent2_id if child.parent2_id && child.should_contact_parent2
    end
  end
end
