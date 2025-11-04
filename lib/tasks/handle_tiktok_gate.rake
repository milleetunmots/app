namespace :children do
  desc "Set the group_status of children registered via /inscription5 between November 2nd and 3rd to not_supported and add a tag to them."
  task handle_tiktok_gate: :environment do
    Child.joins(:source).
      where(source: { channel: 'local_partner' }).
      where(created_at: Date.new(2025, 11, 2).beginning_of_day..Date.new(2025, 11, 3).end_of_day).find_each do |child|
      child.group_status = 'not_supported'
      child.tag_list += ['Tiktok gate']
      child.save
    end
  end
end
