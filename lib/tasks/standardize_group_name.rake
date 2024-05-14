namespace :group do
  desc 'Standardize group name'
  task standardize_name: :environment do
    ActiveRecord::Base.transaction do
      index = 0
      last_month = nil
      Group.where.not(started_at: nil).order(:started_at).find_each do |group|
        next unless group.valid?

        date = group.started_at
        name = date.strftime('%Y/%m/%d').to_s
        if group.expected_children_number&.positive?
          index = date.month == last_month ? index + 1 : 1
          name = "#{name} - #{I18n.t date.strftime('%B')}#{date.strftime('%y')} - #{index}"
          last_month = group.started_at.month
        else
          name = "#{name} - #{group.name}"
        end
        group.name = name
        group.save
      end
    end
  end
end
