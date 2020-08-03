class RedirectionController < ApplicationController

  def visit
    @redirection_url = RedirectionUrl.where(
      id: params[:id],
      security_code: params[:security_code]
    ).first

    head 404 and return if @redirection_url.nil?

    if admin_user_signed_in?
      puts "Not tracking visit since an admin is connected"
    else
      @redirection_url.redirection_url_visits.create!(occurred_at: Time.now)
    end

    redirect_to @redirection_url.redirection_target.medium_url
  end

end
