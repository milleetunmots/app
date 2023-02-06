class ChildrenSupportModule
  class CheckCreditsService
    attr_reader :errors

    def initialize(children_support_module_ids)
      @children_support_module_ids = children_support_module_ids
      @errors = []
    end

    def call
      ChildrenSupportModule.includes(:child, :parent, :support_module)
                           .where(id: @children_support_module_ids)
                           .group_by(&:support_module)
                           .each do |support_module, children_support_modules|
        next if support_module.nil?

        support_module.support_module_weeks.each do |support_module_week|

          # support_module_week.medium.body1.gsub

# body2
# body3
# image1_id    :bigint
#  image2_id    :bigint
#  image3_id    :bigint
#  link1_id     :bigint
#  link2_id     :bigint
#  link3_id     :bigint

          # support_module.additional_medium
        end

        # PRENOM_ENFANT
        # URL # 'https://app.1001mots.org/r/xxxxxx/xx'
      end

      self
    end
  end
end
