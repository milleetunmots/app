class Child
  class CreateService

    attr_reader :errors, :sms_url_form

    def initialize(
      attributes,
      siblings_attributes,
      parent1_attributes,
      mother_attributes,
      father_attributes,
      registration_origin)
      # @sms_url_form = "#{ENV['TYPEFORM_URL']}#child_support_id=#{@child.child_support.id}"
      @attributes = attributes
      @registration_origin = registration_origin
      @siblings_attributes = siblings_attributes
      @parent1_attributes = parent1_attributes,
      @mother_attributes = mother_attributes.merge(gender: 'f', terms_accepted_at: Time.now)
      @father_attributes = father_attributes.merge(gender: 'm', terms_accepted_at: Time.now)
      @errors = []

    end

    def call
      add_registration_origin_as_tag


      self
    end

    private

    def add_registration_origin_as_tag
      @attributes[:tag_list] = case @registration_origin
                               when 3 then 'form-pro'
                               when 2 then 'form-2'
                               else 'site'
                               end
    end

    def build
      @child = Child.new(@attributes.merge(
        parent1_attributes: @parent1_attributes.merge(@mother_attributes),
        parent2_attributes: @father_attributes
      ))
    end

    def build_child_support
      @child.build_child_support if @child.child_support.nil?
    end

    def build_siblings
      @child.siblings.build(@siblings_attributes)
    end





  end
end
