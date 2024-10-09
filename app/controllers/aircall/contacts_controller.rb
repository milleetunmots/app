module Aircall
  class ContactsController < ApplicationController

    def show
      service = Aircall::ConnexionService.new('v1/contacts').get
      # service = Aircall::ContactService.new

      if service.errors.any?
        render json: { error: service.errors.first[:message] }, status: service.errors.first[:status]
      else
        render json: service.response, status: :ok
      end
    end
  end
end
