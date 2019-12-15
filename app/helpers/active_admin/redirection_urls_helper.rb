module ActiveAdmin::RedirectionUrlsHelper

  def redirection_url_child_select_collection
    Child.order(:first_name, :last_name).map(&:decorate)
  end

  def redirection_url_parent_select_collection
    Parent.order(:first_name, :last_name).map(&:decorate)
  end

  def redirection_url_redirection_target_select_collection
    RedirectionTarget.order(:name).map(&:decorate)
  end

end
