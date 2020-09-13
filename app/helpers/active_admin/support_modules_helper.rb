module ActiveAdmin::SupportModulesHelper

  def support_module_ages_select_collection
    SupportModule::AGES.map do |v|
      [
        SupportModule.human_attribute_name("ages.#{v}"),
        v
      ]
    end
  end

end
