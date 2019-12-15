module ActiveAdmin::RedirectionUrlsHelper

  def redirection_url_child_select_collection
    Child.all.map(&:decorate)
  end

  def redirection_url_parent_select_collection
    Parent.all.map(&:decorate)
  end

  def redirection_url_redirection_target_select_collection
    RedirectionTarget.order(:name).map(&:decorate)
  end

end
