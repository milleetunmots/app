class External::BaseController < ActionController::Base
  before_action :authenticate_external_user!
end
