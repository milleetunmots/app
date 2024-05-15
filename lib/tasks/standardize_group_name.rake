namespace :group do
  desc 'Standardize group name'
  task standardize_name: :environment do
    Group.where.not(started_at: nil).find_each do |group|
      group.name = "#{group.started_at.strftime('%Y/%m/%d')} - #{group.name}"
      group.save(validate: false)
    end
  end
end
