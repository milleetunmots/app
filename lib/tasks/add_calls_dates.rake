namespace :groups do
  desc 'Retroactively assign books sent to families to previous children support modules'
  task add_calls_dates: :environment do
		Group.where.not(started_at: nil).each do |group|
      group.set_calls_dates
      group.save(validate: false)
    end
  end
end
