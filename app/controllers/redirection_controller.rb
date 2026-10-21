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

    # N'encode que les caractères hors ASCII imprimable (accents, espaces) : les « % » et « # »
    # de l'url enregistrée sont conservés tels quels, sans double encodage.
    uri = URI.parse(URI::DEFAULT_PARSER.escape(@redirection_url.redirection_target.medium_url, /[^!-~]/))
    child_support_id = @redirection_url.child&.child_support_id

    if uri.host == '1001mots-app1.bubbleapps.io'
      uri.query = [uri.query.presence, URI.encode_www_form(child_support_id: child_support_id)].compact.join('&')
    end

    if uri.host == 'wr1q9w7z4ro.typeform.com'
      uri.fragment = [uri.fragment.presence, "child_support_id=#{child_support_id}&parent_id=#{@redirection_url.parent_id}"].compact.join('&')
    end

    redirect_to uri.to_s
  end
end
