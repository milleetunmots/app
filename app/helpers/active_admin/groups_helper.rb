module ActiveAdmin::GroupsHelper
  def group_select_collection
    Group.order(:id).pluck(:name)
  end
end
