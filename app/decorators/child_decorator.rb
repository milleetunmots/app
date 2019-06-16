class ChildDecorator < BaseDecorator

  def admin_link
    h.link_to name, [:admin, model], class: GENDER_COLORS[model.gender.to_sym]
  end

  def age
    months = model.months
    if months < 24
      h.t 'child_age.months', months: months
    else
      h.t 'child_age.years', years: (months / 12).floor
    end
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
    parent.decorate.admin_link
  end

end
