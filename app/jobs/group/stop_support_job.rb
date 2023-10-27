class Group

  class StopSupportJob < ApplicationJob

    def perform(group_id, end_support_date)
      Group.find(group_id).children.update_all(group_status: 'stopped', group_end: end_support_date)
    end
  end
end
