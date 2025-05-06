module ActiveAdmin::ParentsHelper

  def parent_gender_select_collection
    Parent::GENDERS.map do |v|
      [
        Parent.human_attribute_name("gender.#{v}"),
        v
      ]
    end
  end

  def workshop_parent_select_collection
    Parent.not_excluded_from_workshop.order(:id).map(&:decorate)
  end

  def parent_degree_level_collection
    Parent::DEGREE_LEVELS.map do |v|
      [
        Parent.human_attribute_name("degree_level_at_registration.#{v}"),
        v
      ]
    end
  end

  def parent_degree_obtained_in_collection
    Parent::DEGREE_COUNTRIES.map do |v|
      [
        Parent.human_attribute_name("degree_country_at_registration.#{v}"),
        v
      ]
    end
  end

  def parent_preferred_channel_select_collection
    Parent::COMMUNICATION_CHANNELS.map do |v|
      [
        Parent.human_attribute_name("communication_channel.#{v}"),
        v
      ]
    end
  end

  def parent_book_delivery_location_select_collection
    Parent::BOOK_DELIVERY_LOCATION.map do |v|
      [
        Parent.human_attribute_name("book_delivery_location.#{v}"),
        v
      ]
    end
  end
end
