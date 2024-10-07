class SourcesController < ApplicationController
  skip_before_action :authenticate_admin_user!

  def caf_by_utm
    source = Source.by_caf.by_utm(params[:utm_caf]).first
    response = source ? { id: source.id, name: source.name } : {}
    render json: response.to_json
  end

  def friends
    source = Source.find_by(utm: 'friends')
    render json: { id: source.id, name: source.name }.to_json
  end

  def local_partner_has_department
    department = Source.find(params[:id]).department
    render json: { result: department.present? }.to_json
  end
end
