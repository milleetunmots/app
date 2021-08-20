class ProgramMessageService

  include ProgramMessagesHelper

  attr_reader :errors

  def initialize(planned_date, planned_hour, recipients, message, redirection_target_id = nil)
    @planned_timestamp = Time.zone.parse("#{planned_date} #{planned_hour}").to_i
    @recipients = recipients || []
    @message = message
    @redirection_target = RedirectionTarget.find(redirection_target_id) if redirection_target_id
    @recipient_data = []
    @variables = []
    @errors = []
    @parent_ids, @tag_ids, @group_ids = sort_recipients(@recipients).values
  end

  def call
    check_all_fields_are_present
    return self if @errors.any?

    get_all_variables if @message.match(/\{(.*?)\}/)
    return self if @errors.any?

    find_parent_ids_from_tags
    find_parent_ids_from_groups

    @errors << "Aucun parent à contacter." and return self if @parent_ids.empty?

    format_data_for_spot_hit
    return self if @errors.any?

    @message += " {URL}" if @redirection_target and !@variables.include?("URL")

    service = SpotHit::SendSmsService.new(@recipient_data, @planned_timestamp, @message).call
    @errors = service.errors if service.errors.any?
    self
  end

  protected

  def get_all_variables
    @variables += @message.scan(/\{(.*?)\}/).transpose[0].uniq

    @errors << "Veuillez choisir un lien cible." if @redirection_target.nil? and @variables.include?("URL")
  end

  def format_data_for_spot_hit
    # we need to format phone_numbers as hash inn order to include variables
    if @redirection_target or @variables.include?("PRENOM_ENFANT")
      @recipient_data = {}

      Parent.where(id: @parent_ids).find_each do |parent|
        @recipient_data[parent.id.to_s] = {}

        @recipient_data[parent.id.to_s]["PRENOM_ENFANT"] = parent.first_child&.first_name || "votre enfant"

        if @redirection_target && parent.first_child.present?
          @recipient_data[parent.id.to_s]["URL"] = redirection_url_for_a_parent(parent)&.decorate&.visit_url
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

  def find_parent_ids_from_tags
    @tag_ids.each do |tag_id|
      # taggable_id = id of the parent in our case
      @parent_ids += Tagging.by_taggable_type("Parent").by_tag_id(tag_id).pluck(:taggable_id)
    end
  end

  def find_parent_ids_from_groups
    Group.includes(:children).where(id: @group_ids).find_each do |group|
      group.children.each do |child|
        next if child.has_quit_group

        @parent_ids << child.parent1_id if child.parent1_id && child.should_contact_parent1
        @parent_ids << child.parent2_id if child.parent2_id && child.should_contact_parent2
      end
    end
  end

end
