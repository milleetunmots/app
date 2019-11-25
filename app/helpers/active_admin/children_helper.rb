module ActiveAdmin::ChildrenHelper

  def child_gender_select_collection(with_unknown: false)
    if with_unknown
      [
        [
          Child.human_attribute_name('gender.x'),
          ''
        ]
      ]
    else
      []
    end + Child::GENDERS.map do |v|
      [
        Child.human_attribute_name("gender.#{v}"),
        v
      ]
    end
  end

  def child_parent_select_collection
    Parent.all.map(&:decorate)
  end

  def child_registration_source_select_collection
    Child::REGISTRATION_SOURCES.map do |v|
      [
        Child.human_attribute_name("registration_source.#{v}"),
        v
      ]
    end
  end

end
