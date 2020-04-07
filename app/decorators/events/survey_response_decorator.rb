class Events::SurveyResponseDecorator < EventDecorator

  def name
    [
      related_name,
      model.survey_name
    ].join(' - ')
  end

  def survey_link
    path = polymorphic_path(
      [:admin, model.class],
      q: {
        survey_name_in: [survey_name]
      }
    )

    h.link_to survey_name, path
  end

  def timeline_description
    [
      related_link,
      'a répondu au questionnaire',
      survey_link
    ].join(' ').html_safe
  end

end
