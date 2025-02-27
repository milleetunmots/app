module Typeform
  class AddCafSubscriptionTagService < Typeform::TypeformService

    CAF_SUBSCRIPTION_TYPEFORM_CALENDLY_FIELD = ENV['CAF_SUBSCRIPTION_TYPEFORM_CALENDLY_FIELD'].freeze

    def call
      verify_hidden_variable('child_support_id')
      find_child_support
      return self unless @errors.empty?

      @answers.each do |answer|
        next unless answer[:field][:id] == CAF_SUBSCRIPTION_TYPEFORM_CALENDLY_FIELD
        next if answer[:url].blank?

        tag = Tag.find_or_create_by(name: 'a_souscrit_caf_93')
        @child_support.children.each do |child|
          child.tag_list << tag
          @errors << { message: 'tag adding to child failed', child_id: child.id } unless child.save
        end
      end
      self
    end
  end
end
