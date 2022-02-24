module ActiveAdmin::WorkshopsHelper
  def workshop_topic_select_collection
    Workshop::TOPICS.map do |v|
      [Workshop.human_attribute_name("topic.#{v}"), v]
    end
  end
end
