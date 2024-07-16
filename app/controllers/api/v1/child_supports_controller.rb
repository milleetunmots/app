module Api
  module V1
    class ChildSupportsController < BaseController
      before_action :verify_caller_id, :verifiy_group_id

      def child_support_count
        count
        render json: {
          total: @child_supports.count,
          active: @active_child_support.distinct.count,
          not_active: @not_active_child_support.distinct.count
        }
      end

      private

      def verify_caller_id
        @caller_id = params[:caller_id]
        render json: { error: 'caller_id is required' }, status: :bad_request and return if @caller_id.nil?

        render json: { error: 'Invalid caller_id' }, status: :not_found unless AdminUser.any_caller_with_id?(@caller_id)
      end

      def verifiy_group_id
        @group_id = params[:group_id]
        render json: { error: 'Invalid group_id' }, status: :not_found if @group_id && !Group.exists?(@group_id)
      end

      def count
        @child_supports = ChildSupport.all_supported_by(@caller_id)
        @active_child_support = ChildSupport.active_supported_by(@caller_id)
        @not_active_child_support = ChildSupport.not_active_supported_by(@caller_id)
        return unless @group_id

        @child_supports = @child_supports.in_group(@group_id)
        @active_child_support = @active_child_support.in_group(@group_id)
        @not_active_child_support = @not_active_child_support.in_group(@group_id)
      end
    end
  end
end
