class RedirectionController < ApplicationController
  skip_before_action :authenticate_admin_user!

  def visit
    @redirection_url = RedirectionUrl.where(
      id: params[:id],
      security_code: params[:security_code]
    ).first

    head 404 and return if @redirection_url.nil?

    if admin_user_signed_in?
      puts "Not tracking visit since an admin is connected"
    else
      @redirection_url.redirection_url_visits.create!(occurred_at: Time.zone.now)
    end

    uri = URI.parse(URI::DEFAULT_PARSER.escape(@redirection_url.redirection_target.medium_url))
    if uri.host == '1001mots-app1.bubbleapps.io'
      new_query_ar = URI.decode_www_form(String(uri.query)) << ['child_support_id', @redirection_url.child&.child_support_id]
      uri.query = URI.encode_www_form(new_query_ar)
    end

    uri_string = uri.to_s

    if uri.host == 'wr1q9w7z4ro.typeform.com'
      uri_string << "#child_support_id=#{@redirection_url.child&.child_support_id}&parent_id=#{@redirection_url.parent_id}"
    end

    redirect_to uri_string
  end
end
