class AdminUser

  class StartImpersonationService

    attr_reader :errors, :impersonation

    def initialize(operator:, target:)
      @operator = operator
      @target = target
      @errors = []
    end

    def call
      return fail_with('impersonation.errors.not_authorized') unless @operator.can_impersonate?
      return fail_with('impersonation.errors.target_not_impersonable') unless @target.impersonable?

      @impersonation = AdminUserImpersonation.create!(operator: @operator, target: @target, started_at: Time.current)
      self
    end

    private

    def fail_with(i18n_key)
      @errors << {
        message: I18n.t(i18n_key),
        context: { operator_id: @operator.id, target_id: @target.id }
      }
      self
    end
  end
end
