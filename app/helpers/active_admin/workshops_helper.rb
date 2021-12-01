module ActiveAdmin::WorkshopsHelper
  def workshop_co_animator_select_collection
    AdminUser.order(:name).pluck(:name)
  end

  def workshop_tag_collection
    Tag.order(:name).pluck(:name)
  end

  def parent_collection
    Parent.order(:id).map(&:decorate)
  end

end
