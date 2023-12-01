class Group

  class StopSupportJob < ApplicationJob

    def perform(group_id)
      Group::StopSupportService.new(group_id).call
    end
  end
end
