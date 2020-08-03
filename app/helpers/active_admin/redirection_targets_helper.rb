module ActiveAdmin::RedirectionTargetsHelper

  def redirection_target_medium_select_collection
    Medium.for_redirections.order(:name).kept.map(&:decorate)
  end

end
