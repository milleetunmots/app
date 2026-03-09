class Parent::SendCalendlyReminderService

  REMINDER_MESSAGE = <<~MSG.freeze
    Bonjour,
    Je vais vous appeler dans les prochains jours pour discuter de {PRENOM_ENFANT}.
    Prenez RDV ici : {CALENDLY_LINK}
    A très vite !
    {PRENOM_ACCOMPAGNANTE} de 1001mots
  MSG

  AIRCALL_SEGMENTS_LIMIT_PER_HOUR = 100
  MANUAL_SEGMENTS_MARGIN = 40
  AVAILABLE_SEGMENTS_PER_HOUR = AIRCALL_SEGMENTS_LIMIT_PER_HOUR - MANUAL_SEGMENTS_MARGIN
  ESTIMATED_SEGMENTS_PER_SMS = 2
  MAX_SMS_PER_HOUR_PER_SUPPORTER = AVAILABLE_SEGMENTS_PER_HOUR / ESTIMATED_SEGMENTS_PER_SMS

  BATCH_HOURS = [14, 15, 16, 17].freeze

  attr_reader :errors

  def initialize(sunday_date: Time.zone.today)
    @errors = []
    @sunday_date = sunday_date
    @next_monday = sunday_date.next_occurring(:monday)
  end

  def call
    @errors << { service: 'Parent::SendCalendlyReminderService', error: 'BETA_TEST_CALLERS_EMAIL is not set' } if ENV['BETA_TEST_CALLERS_EMAIL'].blank?
    return self if @errors.any?

    recipients_by_supporter = collect_eligible_recipients_by_supporter
    schedule_batched_messages(recipients_by_supporter)
    self
  end

  private

  def collect_eligible_recipients_by_supporter
    recipients_by_supporter = Hash.new { |h, k| h[k] = [] }

    (0..3).each do |call_index|
      child_supports = eligible_child_supports_for_call(call_index)
        .includes(:supporter, :current_child, :scheduled_calls)

      child_supports.each do |child_support|
        current_child = child_support.current_child
        next unless current_child

        supporter = child_support.supporter

        # envoyer le message aux 2 parents ou pas ???
        if current_child.should_contact_parent1? && child_support.parent1.present?
          recipient = build_recipient(child_support.parent1, child_support, call_index)
          recipients_by_supporter[supporter] << recipient if recipient
        end

        if current_child.should_contact_parent2? && child_support.parent2.present?
          recipient = build_recipient(child_support.parent2, child_support, call_index)
          recipients_by_supporter[supporter] << recipient if recipient
        end
      end
    end

    recipients_by_supporter
  end

  def build_recipient(parent, child_support, call_index)
    calendly_url = parent.calendly_booking_urls&.dig("call#{call_index}")
    return nil if calendly_url.blank?
    return nil if parent.scheduled_calls.scheduled.where(call_session: call_index).exists?

    { parent: parent, child_support: child_support, call_index: call_index, calendly_url: calendly_url }
  end

  def eligible_child_supports_for_call(call_index)
    ChildSupport
      .kept
      .with_valid_supporter_for_calendly
      .where(supporter: { email: ENV['BETA_TEST_CALLERS_EMAIL'].split })
      .where("groups.call#{call_index}_start_date" => @next_monday)
      .where("child_supports.call#{call_index}_status IS NULL OR child_supports.call#{call_index}_status = ''")
      .distinct
  end

  def schedule_batched_messages(recipients_by_supporter)
    recipients_by_supporter.each do |supporter, recipients|
      recipients.each_slice(MAX_SMS_PER_HOUR_PER_SUPPORTER).with_index do |batch, batch_index|
        hour = BATCH_HOURS[batch_index]

        unless hour
          @errors << {
            warning: "Trop de destinataires pour #{supporter.name} (#{recipients.size}) - les batchs au-delà de #{BATCH_HOURS.last}h ne sont pas envoyés",
            supporter_id: supporter.id,
            total_count: recipients.size
          }
          break
        end

        send_time = ActiveSupport::TimeZone['Europe/Paris'].parse("#{@sunday_date.strftime('%Y-%m-%d')} #{hour}:00")
        batch.each { |recipient| schedule_reminder(recipient, send_time) }
      end
    end
  end

  def schedule_reminder(recipient, send_time)
    parent = recipient[:parent]
    child_support = recipient[:child_support]
    supporter = child_support.supporter
    child_name = child_support.current_child&.first_name || 'votre enfant'
    supporter_first_name = supporter.decorate.first_name

    body = REMINDER_MESSAGE.dup
    body.gsub!('{PRENOM_ENFANT}', child_name)
    body.gsub!('{CALENDLY_LINK}', recipient[:calendly_url])
    body.gsub!('{PRENOM_ACCOMPAGNANTE}', supporter_first_name)

    event = Event.create(
      related_id: parent.id,
      related_type: 'Parent',
      body: body,
      type: 'Events::TextMessage',
      occurred_at: send_time,
      message_provider: 'aircall'
    )

    unless event.persisted?
      @errors << {
        error: "Impossible de créer l'event pour le parent #{parent.id}",
        event_errors: event.errors.full_messages
      }
      return
    end

    Aircall::SendMessageJob.set(wait_until: send_time).perform_later(
      supporter.aircall_number_id,
      parent.phone_number,
      body,
      event.id
    )
  end
end
