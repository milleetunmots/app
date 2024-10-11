module Aircall

  class ContactsController < ApplicationController

    skip_before_action :authenticate_admin_user!
    skip_before_action :verify_authenticity_token

    before_action :handle_params

    def create
      @service = Aircall::ContactService.new(contact_form: @contact_form).post
      if @service.errors.empty?
        render json: @service.response, status: params[:id].present? ? :ok : :created
      else
        handle_render_with_bad_request
      end
    end

    def update
      if @phone_number_label && @phone_number_value
        @phone_number_id = Aircall::ContactService.new(id: @id).get.response['phone_numbers'].first['id']
        put
        return
      end
      @service = Aircall::ContactService.new(id: @id, contact_form: @contact_form).post
      if @service.errors.empty?
        render json: @service.response, status: params[:id].present? ? :ok : :created
      else
        handle_render_with_bad_request
      end
    end

    def put
      @service = Aircall::ContactService.new(id: @id, phone_number_id: @phone_number_id, phone_number_form: @phone_number_form).put
      if @service.errors.empty?
        render json: @service.response, status: :accepted
      else
        handle_render_with_bad_request
      end
    end

    def read
      @service = Aircall::ContactService.new(id: @id).get
      if @service.errors.empty?
        render json: @service.response, status: :ok
      else
        render json: { error: @service.errors.first[:message] }, status: @service.errors.first[:status]
      end
    end

    def delete
      @service = Aircall::ContactService.new(id: @id).delete
      if @service.errors.any?
        render json: { error: @service.errors.first[:message] }, status: @service.errors.first[:status]
      else
        head :no_content
      end
    end

    private

    def handle_params
      @id = params[:id]
      @phone_number_id = params[:phone_number_id]
      @phone_number_label = params[:phone_number_label]
      @phone_number_value = params[:phone_number_value]
      @phone_number_form = {
        label: params[:phone_number_label],
        value: params[:phone_number_value]
      }
      @contact_form = {
        first_name: params[:first_name],
        last_name: params[:last_name],
        information: params[:information]
      }
      return if @id

      @contact_form[:phone_numbers] = [
        {
          label: params[:phone_number_label],
          value: params[:phone_number_value]
        }
      ]
    end

    def handle_render_with_bad_request
      if @service.errors.pluck(:missing_parameter).any?
        render json: { error: @service.errors.first[:message], missing_parameters: @service.errors.pluck(:missing_parameter).join(', ') }, status: :bad_request
      else
        render json: { error: @service.errors.first[:message] }, status: @service.errors.first[:status]
      end
    end
  end
end
