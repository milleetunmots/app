class ProgramModuleService < ProgramMessageService

  def initialize(planned_date, recipients, module_to_send)
    @starting_date = Time.zone.parse(planned_date)
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
    check_all_fields_are_present
    return self if @errors.any?

    sort_recipients
    find_parent_ids_from_tags
    find_parent_ids_from_groups
    get_all_phone_numbers
    @errors << "Aucun parent à contacter." and return self if @recipient_data.empty?

    # generate_phone_number_from_data if @redirection_target || @variables.include?("PRENOM_ENFANT")
    # return self if @errors.any?

    support_module_week_list = SupportModule.find(@module_to_send).support_module_weeks

    support_module_week_list.each do |support_module_week|
      text_message_bundle = Medium.find(support_module_week.medium_id)
      if support_module_week.additional_medium_id
        first_service = SpotHit::SendSmsService.new(
          @recipient_data, Time.zone.parse("#{@starting_date} 12:30").to_i, text_message_bundle.body1
        ).call
        @errors = first_service.errors if first_service.errors.any?

        # second_service = SpotHit::SendSmsService.new(
        #   @recipient_data, Time.zone.parse("#{@starting_date} 12:30").to_i, text_message_bundle.body1
        # ).call
        # @errors = second_service.errors if second_service.errors.any?
        #
        # additional_medium = Medium.find(support_module_week.additional_medium_id)

        # p additional_medium.body1
      # else

      end

      # p text_message_bundle.body2
      # p text_message_bundle.body3


    end

    self

  end

  def check_all_fields_are_present
    @errors << "Tous les champs doivent être complétés." if !@starting_date.present? || @recipients.empty? || @module_to_send.empty?
    @errors << "La date de démarrage doit être un lundi" unless @starting_date.monday?
  end

end
