class Parent

  class HandleStopService

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
      return self unless parents.all? { |parent| stop_message_created?(parent) }

      parents.each { |parent| stop_contacting(parent) }
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
      parent.children.where.not(group_id: nil).where(group_status: %w[active paused]).find_each do |child|
        child.parent1_id == parent.id ? child.should_contact_parent1 = false : child.should_contact_parent2 = false
        stop_support(child) unless child.should_contact_parent1 || child.should_contact_parent2
        child.save(validate: false)
      end
    end

    def stop_support(child)
      child.group_status = 'stopped'
      child.group_end = Time.zone.now
    end
  end
end
