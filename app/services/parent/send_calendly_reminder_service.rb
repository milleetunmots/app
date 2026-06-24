class Parent::SendCalendlyReminderService

  AIRCALL_SEGMENTS_LIMIT_PER_HOUR = 100
  MANUAL_SEGMENTS_MARGIN = 40
  AVAILABLE_SEGMENTS_PER_HOUR = AIRCALL_SEGMENTS_LIMIT_PER_HOUR - MANUAL_SEGMENTS_MARGIN
  ESTIMATED_SEGMENTS_PER_SMS = 2
  MAX_SMS_PER_HOUR_PER_SUPPORTER = AVAILABLE_SEGMENTS_PER_HOUR / ESTIMATED_SEGMENTS_PER_SMS

  REMINDER_OFFSET_DAYS = 2
  BATCH_HOURS = [14, 15, 16, 17].freeze

  attr_reader :errors

  def initialize(date: Time.zone.today)
    @errors = []
    @date = date
  end

  def call
    @errors << { service: 'Parent::SendCalendlyReminderService', error: 'BETA_TEST_CALLERS_EMAIL is not set' } if ENV['BETA_TEST_CALLERS_EMAIL'].blank?
    return self if @errors.any?

    recipients_by_supporter = collect_eligible_recipients_by_supporter
    ## Si ça arrive, modifier l'algo de rate limiting pour mieux étaler les envois
    Rollbar.warning('Parent::SendCalendlyReminderService', warning: "Il y a plus de 60 accompagnantes. On risque de dépasser le rate limiting d'aircall par organisation.") if recipients_by_supporter.keys.size > 59
    schedule_batched_messages(recipients_by_supporter)
    self
  end

  private

  # Date d'envoi du 1er SMS de prise de RDV pour laquelle la relance est due
  # aujourd'hui (J+REMINDER_OFFSET_DAYS après le 1er SMS).
  def initial_message_target_date
    @date - REMINDER_OFFSET_DAYS.days
  end

  def collect_eligible_recipients_by_supporter
    recipients_by_supporter = Hash.new { |h, k| h[k] = [] }

    (0..3).each do |call_index|
      child_supports = eligible_child_supports_for_call(call_index)
                       .includes(:supporter, :current_child, :scheduled_calls)

      child_supports.each do |child_support|
        recipients_for(child_support, call_index).each do |recipient|
          recipients_by_supporter[child_support.supporter] << recipient
        end
      end
    end

    recipients_by_supporter
  end

  def recipients_for(child_support, call_index)
    current_child = child_support.current_child
    return [] unless current_child

    # Pas de relance si la plage de RDV de la famille est déjà finie, ni son
    # dernier jour : trop tard pour que l'accompagnante décroche des RDV.
    end_date = child_support.call_session_end_date(call_index)
    return [] if end_date.blank? || end_date <= @date

    [
      (child_support.parent1 if current_child.should_contact_parent1?),
      (child_support.parent2 if current_child.should_contact_parent2?)
    ].compact.filter_map { |parent| build_recipient(parent, child_support, call_index) }
  end

  def build_recipient(parent, child_support, call_index)
    calendly_url = parent.calendly_booking_urls&.dig("call#{call_index}")
    return nil if calendly_url.blank?
    return nil if initial_message_date(parent, call_index) != initial_message_target_date
    return nil if child_support.scheduled_calls.any? { |sc| sc.call_session == call_index && sc.scheduled? }

    { parent: parent, child_support: child_support, call_index: call_index, calendly_url: calendly_url }
  end

  def initial_message_date(parent, call_index)
    raw = parent.calendly_initial_booking_dates&.dig("call#{call_index}")
    return nil if raw.blank?

    begin
      raw.to_date
    rescue ArgumentError, TypeError
      nil
    end
  end

  # Sur-ensemble SQL : familles beta dont la fenêtre de session de cohorte est
  # encore en cours. Le 1er SMS partant au plus tôt à J-3 du début effectif et
  # la relance 2 jours après, une session relançable aujourd'hui commence au
  # plus tard demain. Le ciblage précis (1er SMS envoyé à
  # J-REMINDER_OFFSET_DAYS, plage effective non finie) est affiné en Ruby
  # ci-dessus.
  def eligible_child_supports_for_call(call_index)
    ChildSupport
      .kept
      .with_valid_supporter_for_calendly
      .where(supporter: { email: ENV['BETA_TEST_CALLERS_EMAIL'].split })
      .where("groups.call#{call_index}_start_date <= ?", @date + 1.day)
      .where("groups.call#{call_index}_end_date > ?", @date)
      .where("child_supports.call#{call_index}_status IS NULL OR child_supports.call#{call_index}_status = ''")
      .distinct
  end

  def schedule_batched_messages(recipients_by_supporter)
    recipients_by_supporter.each_with_index do |(supporter, recipients), supporter_index|
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

        base_time = ActiveSupport::TimeZone['Europe/Paris'].parse("#{@date.strftime('%Y-%m-%d')} #{hour}:00") + supporter_index.minutes
        batch.each do |recipient|
          schedule_reminder(recipient, base_time)
        end
      end
    end
  end

  def schedule_reminder(recipient, send_time)
    Aircall::SendCalendlyReminderJob.set(wait_until: send_time).perform_later(
      recipient[:child_support].id,
      recipient[:call_index],
      recipient[:parent].id,
      recipient[:calendly_url]
    )
  end
end
