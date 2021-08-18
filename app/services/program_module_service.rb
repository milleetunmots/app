class ProgramModuleService < ProgramMessageService

  def initialize(planned_date, recipients, module_to_send)
    @planned_timestamp = Time.zone.parse(planned_date.to_s).to_i
    @recipients = recipients || []
    @module_to_send = module_to_send
    @tag_ids = []
    @parent_ids = []
    @group_ids = []
    @recipient_data = []
    @variables = []
    @errors = []
    @message = ""
  end

  def call
    super
  end

  def check_all_fields_are_present
    @errors << "Tous les champs doivent être complétés." if !@planned_timestamp.present? || @recipients.empty? || @module_to_send.empty?
  end

end
