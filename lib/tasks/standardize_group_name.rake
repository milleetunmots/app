namespace :group do
  desc 'Standardize group name'
  task standardize_name: :environment do
    index = 0
    last_month = nil
    Group.effective_group.order(:started_at).find_each do |group|
      date = group.started_at
      index = date.month == last_month ? index + 1 : 1
      name = "#{date.strftime('%Y/%m/%d')} - #{I18n.t date.strftime('%B')}#{date.strftime('%y')} - #{index}"
      last_month = group.started_at.month
      group.name = name
      group.save!
    end
  end
end
