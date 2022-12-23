module ActiveAdmin::EventsHelper

  def survey_response_survey_name_select_collection
    Events::SurveyResponse.survey_names.sort_by(&:downcase)
  end

  def workshop_participation_parent_presence
    Event::PARENT_PRESENCES.map { |v| [Event.human_attribute_name("parents_presence.#{v}"), v]}
  end
end
