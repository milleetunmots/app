module Api
  module V1
    class BaseController < ApplicationController
      before_action :verify_token

      private

      def verify_token
        @token = request.headers['Authorization']
        render json: { error: 'Token is required' }, status: :unauthorized and return unless token_present?

        render json: { error: 'Invalid token' }, status: :unauthorized unless valid_token?
      end

      def valid_token?
        @token == ENV['API_TOKEN']
      end

      def token_present?
        @token.present?
      end
    end
  end
end
