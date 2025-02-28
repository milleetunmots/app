module Typeform
  class AddCafSubscriptionTagService < Typeform::TypeformService

    CAF_SUBSCRIPTION_TYPEFORM_CALENDLY_FIELD = ENV['CAF_SUBSCRIPTION_TYPEFORM_CALENDLY_FIELD'].freeze

    def call
      return self if ENV['CAF_SUBSCRIPTION'].nil?

      verify_hidden_variable('cs')
      find_child_support
      return self unless @errors.empty?

      @answers.each do |answer|
        next unless answer[:field][:id] == CAF_SUBSCRIPTION_TYPEFORM_CALENDLY_FIELD
        next if answer[:url].blank?
        return self unless 'inscrit_via_caf_93'.in? @child_support.tag_list

        tag = Tag.find_or_create_by(name: 'a_souscrit_caf_93')
        @child_support.tag_list << tag
        @errors << { message: 'tag adding to child_support failed', child_support_id: @child_support.id } unless @child_support.save
        @child_support.children.each do |child|
          child.tag_list << tag
          @errors << { message: 'tag adding to child failed', child_id: child.id } unless child.save
        end
      end
      self
    end

    def find_child_support
      @child_support = ChildSupport.find_by(id: @hidden_variables[:cs])
      @errors << { message: 'ChildSupport not found', child_support_id: @hidden_variables[:cs] } unless @child_support
    end
  end
end
