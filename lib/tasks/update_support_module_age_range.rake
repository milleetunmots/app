namespace :support_module do
  desc 'Update support module age range'
  task update_age_rage: :environment do
    updating('four_to_nine', 'four_to_ten')
    updating('ten_to_fifteen', 'eleven_to_sixteen')
    updating('sixteen_to_twenty_three', 'seventeen_to_twenty_two')
    updating('twenty_four_and_more', 'twenty_three_and_more')
  end

  def updating(old_age_range, new_age_range)
    SupportModule.where("'#{old_age_range}' = ANY(age_ranges)").find_each do |support_module|
      age_ranges = support_module.age_ranges.reject! { |range| range == old_age_range } << new_age_range
      support_module.update!(age_ranges: age_ranges)
    end
  end
end
