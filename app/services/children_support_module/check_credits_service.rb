class ChildrenSupportModule
  class CheckCreditsService
    attr_reader :errors

    def initialize(children_support_module_ids)
      @children_support_module_ids = children_support_module_ids
      @errors = []
      @sms_to_send_count = 0
      @mms_to_send_count = 0
    end

    def call
      count_sms_and_mms

      credit_service = SpotHit::GetCreditsService.new.call
      @errors = credit_service.errors
      return self if @errors.any?

      @errors << "Pas assez de crédits sms sur SPOT-HIT : #{@sms_to_send_count} crédits sont nécéssaires." if @sms_to_send_count > credit_service.sms
      @errors << "Pas assez de crédits mms sur SPOT-HIT : #{@mms_to_send_count} crédits sont nécéssaires." if @mms_to_send_count > credit_service.mms
      self
    end

    private

    def count_sms_and_mms
      ChildrenSupportModule.includes(:child, :support_module)
                           .where(id: @children_support_module_ids)
                           .group_by(&:support_module)
                           .each do |support_module, children_support_modules|
        next if support_module.nil?

        children_support_modules.each do |children_support_module|
          support_module.support_module_weeks.each do |support_module_week|
            week_medium = support_module_week.medium
            child = children_support_module.child

            count_sms_and_mms_for_specific_message(week_medium.image1_id, week_medium.body1, child) if week_medium.body1.present?
            count_sms_and_mms_for_specific_message(week_medium.image2_id, week_medium.body2, child) if week_medium.body2.present?
            count_sms_and_mms_for_specific_message(week_medium.image3_id, week_medium.body3, child) if week_medium.body3.present?
            count_sms_and_mms_for_specific_message(nil, support_module_week.additional_medium.body1, child) if support_module_week.additional_medium&.body1&.present?
          end
        end
      end
    end

    def format_text(text, child)
      text = text.gsub("{URL}", 'https://app.1001mots.org/r/xxxxxx/xx')
      text = text.gsub('{PRENOM_ENFANT}', child.first_name)
      text = text.gsub(/[\^€}{\[\]~\\]/, 'xx')
      text
    end

    def count_sms_and_mms_for_specific_message(image, text, child)
      if image.present?
        @mms_to_send_count += 1
      else
        formated_text = format_text(text, child)
        @sms_to_send_count += (formated_text.size / 160) + 1
      end
    end
  end
end
