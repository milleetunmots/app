class SourcesController < ApplicationController

  def caf_by_utm
    source = Source.by_caf.by_utm(params[:utm_caf]).first
    response = source ? { id: source.id, name: source.name } : {}
    render json: response.to_json
  end

  def friends
    source = Source.find(34)
    render json: { id: source.id, name: source.name }.to_json
  end

  def local_partner_has_department
    department = Source.find(params[:id]).department
    render json: { result: department.present? }.to_json
  end
end
