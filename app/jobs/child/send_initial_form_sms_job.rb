class Child::SendInitialFormSmsJob < ApplicationJob
  def perform(parent1_id, message)
    child_support = Parent.find(parent1_id).current_child&.child_support
    return if child_support.nil?
    return if child_support.enrollment_reasons.any?

    SpotHit::SendSmsService.new([parent1_id], Time.zone.now.to_i, message).call
  end
end