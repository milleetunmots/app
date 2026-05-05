module Aircall
  class SendCalendlyReminderJob < ApplicationJob
    REMINDER_MESSAGE = <<~MSG.freeze
      Bonjour,
      Je vais vous appeler dans les prochains jours pour discuter de {PRENOM_ENFANT}.
      Prenez RDV ici : {CALENDLY_LINK}
      A très vite !
      {PRENOM_ACCOMPAGNANTE} de 1001mots
    MSG

    def perform(child_support_id, call_session, parent_id, calendly_url)
      child_support = ChildSupport.find_by(id: child_support_id)
      if child_support.nil?
        Rollbar.error('Aircall::SendCalendlyReminderJob',
                      error: "La fiche de suivi n'a pas été trouvée",
                      child_support_id: child_support_id)
        return
      end

      parent = Parent.find_by(id: parent_id)
      if parent.nil?
        Rollbar.error('Aircall::SendCalendlyReminderJob',
                      error: "Le parent n'a pas été trouvé",
                      parent_id: parent_id)
        return
      end

      supporter = child_support.supporter
      if supporter.nil?
        Rollbar.error('Aircall::SendCalendlyReminderJob',
                      error: "La fiche de suivi n'a pas pas d'accompagnante",
                      child_support_id: child_support_id)
        return
      end

      if supporter.aircall_number_id.blank?
        Rollbar.error('Aircall::SendCalendlyReminderJob',
                      error: "L'accompagnante n'a pas de numéro aircall",
                      supporter_id: supporter.id)
        return
      end

      return if rdv_already_booked?(child_support, call_session)
      return if call_status_already_filled?(child_support, call_session)

      body = build_body(child_support, supporter, calendly_url)

      event = Event.new(
        related_id: parent_id,
        related_type: 'Parent',
        body: body,
        type: 'Events::TextMessage',
        occurred_at: Time.zone.now,
        message_provider: 'aircall'
      )

      unless event.save
        Rollbar.error('Aircall::SendCalendlyReminderJob',
                      error: "Impossible de créer l'event text",
                      related_id: parent_id,
                      body: body)
        return
      end

      Aircall::SendMessageJob.perform_later(
        supporter.aircall_number_id,
        parent.phone_number,
        body,
        event.id
      )

      parent.calendly_last_booking_dates ||= {}
      parent.calendly_last_booking_dates["call#{call_session}"] = Time.zone.now.to_s
      return if parent.save

      Rollbar.error('Aircall::SendCalendlyReminderJob',
                    error: 'Impossible de modifier le parent',
                    parent_id: parent.id,
                    call_session: call_session,
                    booking_date: Time.zone.now.to_s)
    end

    private

    def rdv_already_booked?(child_support, call_session)
      child_support.scheduled_calls.any? { |sc| sc.call_session == call_session && sc.scheduled? }
    end

    def call_status_already_filled?(child_support, call_session)
      status = child_support.send("call#{call_session}_status")
      status.present?
    end

    def build_body(child_support, supporter, calendly_url)
      child_name = child_support.current_child&.first_name || 'votre enfant'
      supporter_first_name = supporter.decorate.first_name

      body = REMINDER_MESSAGE.dup
      body.gsub!('{PRENOM_ENFANT}', child_name)
      body.gsub!('{CALENDLY_LINK}', calendly_url)
      body.gsub!('{PRENOM_ACCOMPAGNANTE}', supporter_first_name)
      body
    end
  end
end
