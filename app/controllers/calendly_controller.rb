class CalendlyController < ApplicationController
  skip_before_action :authenticate_admin_user!

  def scheduling

  end
end
