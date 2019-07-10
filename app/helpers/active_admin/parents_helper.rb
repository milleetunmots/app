module ActiveAdmin::ParentsHelper

  def parent_gender_select_collection
    Hash[
      Parent::GENDERS.map do |v|
        [
          Parent.human_attribute_name("gender.#{v}"),
          v
        ]
      end
    ]
  end

end
