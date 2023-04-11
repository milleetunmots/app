require 'sidekiq-scheduler'

class Child::UpdateChildrenWorkshopAvailabilityJob < ApplicationJob

  def perform
    Child.update_all(available_for_workshops: false)

    if Time.zone.today.month <= 8
      Child.where(birthdate: Date.new(Time.zone.today.year - 3, 1, 1)..Date.new(Time.zone.today.year, 12, 31)).update_all(available_for_workshops: true)
    else
      Child.where(birthdate: Date.new(Time.zone.today.year - 2, 1, 1)..Date.new(Time.zone.today.year, 12, 31)).update_all(available_for_workshops: true)
    end
  end
end
