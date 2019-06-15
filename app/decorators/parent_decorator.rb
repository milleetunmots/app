class ParentDecorator < BaseDecorator

  def email
    h.mail_to model.email
  end

  GENDER_COLORS = {
    m: :green,
    f: :blue
  }

  def gender
    arbre do
      status_tag Parent.human_attribute_name("gender.#{model.gender}"), class: GENDER_COLORS[model.gender.to_sym]
    end
  end

  def name
    [model.first_name, model.last_name].join ' '
  end

  def phone_number
    phone = Phonelib.parse model.phone_number
    phone.national
  end

end
