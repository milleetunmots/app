module ActiveAdmin::EventsHelper

  def survey_response_survey_name_select_collection
    Events::SurveyResponse.survey_names.sort_by(&:downcase)
  end

end
