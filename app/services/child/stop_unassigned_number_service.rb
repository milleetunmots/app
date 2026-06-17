class Child::StopUnassignedNumberService < ProgramMessageService

  attr_reader :child_supports_stopped

  def initialize
    @child_supports = ChildSupport.with_a_child_in_active_group.with_unassigned_number
    @child_supports_stopped = []
  end

  def call
    @child_supports.find_each do |child_support|
      call_status = []
      (0..3).each do |call_idx|
        call_status << child_support.send("call#{call_idx}_status")
      end
      call_status.reject!(&:blank?)
      next if call_status.last != 'Numéro erroné'

      @child_supports_stopped << child_support.id
      new_important_info = "Accompagnement arrêté le #{Time.zone.today.strftime("%d/%m/%Y")} pour cause de numéro erroné.\n\n" + child_support.important_information.to_s
      child_support.update(important_information: new_important_info, support_stopped_for_unassigned_number_at: Time.zone.now)
      parent1 = child_support.parent1
      parent2 = child_support.parent2
      child_support.children.update(group_status: 'stopped')
      child_support.children.each do |c|
        # NB: la condition `c.parent1 == parent1 || parent2` est un comportement pré-existant volontairement conservé ; les marqueurs reflètent fidèlement ce que l'arrêt a décoché.
        if (c.parent1 == parent1 || parent2) && c.should_contact_parent1
          c.should_contact_parent1 = false
          c.contact_parent1_unset_for_unassigned_number = true
        end
        if (c.parent2 == parent1 || parent2) && c.should_contact_parent2
          c.should_contact_parent2 = false
          c.contact_parent2_unset_for_unassigned_number = true
        end
        c.save(validate: false)
      end
    end
    self
  end
end
