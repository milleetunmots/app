class ChildDecorator < BaseDecorator

  def age
    years = ((Time.zone.now - model.birthdate.to_time) / 1.year.seconds)
    if years < 2
      return h.t 'child_age.months', months: (years*12).floor
    end
    h.t 'child_age.years', years: years.floor
  end

  def birthdate
    h.l model.birthdate, format: :default
  end

  def created_at_date
    h.l model.created_at.to_date, format: :default
  end

  GENDER_COLORS = {
    m: :blue,
    f: :rose
  }

  def gender
    arbre do
      status_tag Child.human_attribute_name("gender.#{model.gender}"), class: GENDER_COLORS[model.gender.to_sym]
    end
  end

  def name
    [model.first_name, model.last_name].join ' '
  end

  def parent1
    parent model.parent1
  end

  def parent2
    parent model.parent2
  end

  private

  def parent(parent)
    return nil unless parent
    h.link_to parent.decorate.name, [:admin, parent], class: GENDER_COLORS[parent.gender.to_sym]
  end

end
