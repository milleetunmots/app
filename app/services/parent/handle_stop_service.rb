class Parent

  class HandleStopService

    # Un enfant désengagé garde son statut et sa fin de cohorte : on ne perd pas l'information du désengagement.
    GROUP_STATUS_WITHOUT_CONTACT = {
      'active' => 'stopped',
      'paused' => 'stopped',
      'waiting' => 'not_supported'
    }.freeze

    attr_reader :errors

    def initialize(phone_number:, occurred_at:, spot_hit_message_id: nil, spot_hit_rcs_id: nil)
      @phone_number = phone_number
      @occurred_at = occurred_at
      @spot_hit_message_id = spot_hit_message_id
      @spot_hit_rcs_id = spot_hit_rcs_id
      @errors = []
    end

    def call
      parents = Parent.where(phone_number: @phone_number).to_a
      # Tout ou rien : un STOP à moitié enregistré serait dupliqué au rejeu du webhook.
      ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback unless parents.all? { |parent| stop_message_created?(parent) }

        parents.each { |parent| stop_contacting(parent) }
      end
      self
    end

    private

    def stop_message_created?(parent)
      stop_message = Events::TextMessage.new(
        related: parent,
        body: 'STOP',
        spot_hit_message_id: @spot_hit_message_id,
        spot_hit_rcs_id: @spot_hit_rcs_id,
        spot_hit_status: 1,
        occurred_at: @occurred_at,
        originated_by_app: false
      )
      return true if stop_message.save

      @errors << { message: "Le STOP n'a pas pu être enregistré", context: { parent_id: parent.id, errors: stop_message.errors.full_messages } }
      false
    end

    def stop_contacting(parent)
      parent.children.find_each do |child|
        # Recharge l'enfant sous verrou : un STOP simultané de l'autre parent a pu décocher sa case.
        child.with_lock do
          child.parent1_id == parent.id ? child.should_contact_parent1 = false : child.should_contact_parent2 = false
          end_support(child) unless parent_to_contact?(child)
          child.save(validate: false)
        end
      end
    end

    def parent_to_contact?(child)
      child.should_contact_parent1 || (child.should_contact_parent2 && child.parent2_id.present?)
    end

    def end_support(child)
      group_status = GROUP_STATUS_WITHOUT_CONTACT[child.group_status]
      return unless group_status
      # Un enfant arrêté doit être dans une cohorte (Child#valid_group_status), contrôle que save(validate: false) ne fait pas.
      return if group_status == 'stopped' && child.group_id.nil?

      child.group_status = group_status
      child.group_end = Time.zone.now if group_status == 'stopped'
    end
  end
end
