class ChangeAgeRangesOfSupportModules < ActiveRecord::Migration[6.0]
  def change
    SupportModule.where("'less_than_six' = ANY (age_ranges)").find_each do |support_module|
      support_module.age_ranges = support_module.age_ranges - ['less_than_six'] + ['less_than_five']
      support_module.save!
    end

    SupportModule.where("'six_to_eleven' = ANY (age_ranges)").find_each do |support_module|
      support_module.age_ranges = support_module.age_ranges - ['six_to_eleven'] + ['five_to_eleven']
      support_module.save!
    end
  end
end
