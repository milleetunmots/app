module ActiveAdmin::ChildrenSupportModulesHelper

  def book_condition_select_collection
    ChildrenSupportModule::CONDITIONS.map do |v|
      [
        ChildrenSupportModule.human_attribute_name("condition.#{v}"),
        v
      ]
    end
  end

end
