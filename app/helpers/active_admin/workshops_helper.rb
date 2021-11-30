module ActiveAdmin::WorkshopsHelper
  def workshop_co_animator_select_collection
    AdminUser.order(:name).map(&:decorate)
  end

  def parent_collection
    Parent.order(:id).map(&:decorate)
  end

end
