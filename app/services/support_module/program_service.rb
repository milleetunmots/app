class SupportModule::ProgramService

  attr_reader :errors

  def initialize(support_module, recipients:)
    @support_module = support_module
    @recipients = recipients
    @errors = []
    @hour = nil
    @date = nil
  end

  def call
    @errors << "La date de démarrage doit être un mardi" unless @support_module.start_at&.tuesday?
    return self if @errors.any?

    @support_module.support_module_weeks.each do |support_module_week|
      next if support_module_week.medium.nil?

      (1..3).each do |index|
        next_date_and_hour(support_module_week)

        next if support_module_week.medium.send("body#{index}").blank?

        image = Media::Image.find_by(id: support_module_week.medium.send("image#{index}_id"))
        redirection_target = RedirectionTarget.find_by(medium_id: support_module_week.medium.send("link#{index}_id"))

        program_message(
          @date,
          @hour,
          @recipients,
          support_module_week.medium.send("body#{index}"),
          image&.spot_hit_id,
          redirection_target&.id
        )
      end

      next if support_module_week.additional_medium.nil?

      next_date_and_hour(support_module_week)

      image = Media::Image.find_by(id: support_module_week.additional_medium.image1_id)
      redirection_target = RedirectionTarget.find_by(medium_id: support_module_week.additional_medium.link1_id)

      program_message(
        @date,
        @hour,
        @recipients,
        support_module_week.additional_medium.body1,
        image&.spot_hit_id,
        redirection_target&.id
      )
    end

    self
  end

  private

  def program_message(date, hour, recipients, message, image_id, redirection_target_id)
    service = ProgramMessageService.new(
      date,
      hour,
      recipients,
      message,
      image_id,
      redirection_target_id
    ).call
    @errors += service.errors
  end

  def next_date_and_hour(support_module_week)
    if @hour.nil? || @date.nil?
      @hour = "12:30"
      @date = @support_module.start_at
    else
      sms_count = 0
      sms_count += 1 if support_module_week.medium.body1
      sms_count += 1 if support_module_week.medium.body2
      sms_count += 1 if support_module_week.medium.body3
      sms_count += 1 if support_module_week.additional_medium

      @date = next_date(@date, sms_count)
      @hour = @date.saturday? ? "14:00" : "12:30"
    end
  end

  def next_date(date, sms_count)
    return date.next_day(2) if date.tuesday?
    return date.next_day(3) if date.saturday?
    if sms_count < 4
      return date.next_day(2) if date.thursday?
    else
      return date.next_day if date.thursday?
      return date.next_day if date.friday?
    end
  end
end
