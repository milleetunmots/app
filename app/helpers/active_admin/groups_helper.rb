module ActiveAdmin::GroupsHelper
  def group_select_collection
    Group.order(:id).pluck(:name)
  end

  def group_type_of_support_select_collection
    Group::TYPE_OF_SUPPORT_OPTIONS.map do |v|
      [
        Group.human_attribute_name("type_of_support.#{v}"),
        v
      ]
    end
  end
end
