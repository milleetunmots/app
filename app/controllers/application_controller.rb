class ApplicationController < ActionController::Base
  def status
    render plain: 'OK', status: 200
  end
end
