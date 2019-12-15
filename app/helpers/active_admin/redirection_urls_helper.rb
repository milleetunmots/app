module ActiveAdmin::RedirectionUrlsHelper

  def redirection_url_redirection_target_select_collection
    RedirectionTarget.order(:name).map(&:decorate)
  end

end
