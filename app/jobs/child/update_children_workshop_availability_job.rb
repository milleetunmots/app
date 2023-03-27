require 'sidekiq-scheduler'

class Child::UpdateChildrenWorkshopAvailabilityJob < ApplicationJob

  def perform
    children_available =  if Date.today.month <= 8
                            Child.where(birthdate: Date.new(Date.today.year - 3, 1, 1)..Date.new(Date.today.year, 12, 31))
                          else
                            Child.where(birthdate: Date.new(Date.today.year - 2, 1, 1)..Date.new(Date.today.year, 12, 31))
                          end

    Child.all.each do |child|
      child.update_attribute('available_for_workshops', children_available.include?(child) ? true : false)
    end
  end
end
