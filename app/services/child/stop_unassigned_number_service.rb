class Child::StopUnassignedNumberService < ProgramMessageService

  attr_reader :child_supports_stopped

  def initialize
    @child_supports = ChildSupport.with_a_child_in_active_group.with_unassigned_number
    @child_supports_stopped = []
  end

  def call
    @child_supports.find_each do |child_support|
      call_status = []
      (0..5).each do |call_idx|
        call_status << child_support.send("call#{call_idx}_status")
      end
      call_status.reject!(&:blank?)
      next if call_status.last != 'Numéro erroné'

      @child_supports_stopped << child_support.id
      child_support.children.update(group_status: 'stopped')
    end
    self
  end
end
