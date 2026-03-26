class TypeformRedirectController < ApplicationController
  skip_before_action :authenticate_admin_user!

  def initial_form
    parent = Parent.find_by(security_token: params[:st])
    head :not_found and return if parent.nil?

    @tf_hidden = { st: parent.security_token }

    parent.children.first(3).each_with_index do |child, i|
      @tf_hidden["cn#{i + 1}"] = child.first_name
      @tf_hidden["ccm#{i + 1}"] = child.months
    end
  end
end
