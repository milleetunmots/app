module Aircall
  class ContactsController < ApplicationController

    def show
      service = Aircall::ConnexionService.new('v1/contacts')
      response = service.get

      if response[:error]
        render json: { error: response[:error] }, status: response[:status]
      else
        render json: response, status: :ok
      end
    end
  end
end
