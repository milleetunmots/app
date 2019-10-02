class ChildDecorator < BaseDecorator

  def admin_link(options = {})
    with_icon = options.delete(:with_icon)

    txt = name
    if with_icon
      txt = h.content_tag(:i, '', class: "fas fa-#{icon_class}") + "&nbsp;".html_safe + txt
    end
    h.link_to txt, [:admin, model], { class: GENDER_COLORS[safe_gender.to_sym] }.merge(options)
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
    f: :rose,
    x: :grey
  }
  GENDER_CLASSES = {
    m: :male,
    f: :female,
    x: :unknown
  }

  def safe_gender
    model.gender || 'x'
  end

  def gender
    arbre do
      status_tag Child.human_attribute_name("gender.#{safe_gender}"), class: GENDER_COLORS[safe_gender.to_sym]
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

  def icon_class
    :baby
  end

  def as_autocomplete_result
    h.content_tag :div, class: "child #{GENDER_CLASSES[safe_gender.to_sym]}" do
      (
        h.content_tag :div, class: :name do
          name
        end
      ) + (
        h.content_tag :div, class: :age do
          age
        end
      )
    end
  end

  def child_support_status
    arbre do
      if child_support = model.child_support
        a href: h.auto_url_for(child_support) do
          status_tag :yes
        end
      else
        status_tag :no
      end
    end
  end

  private

  def parent(parent)
    return nil unless parent
    parent.decorate.admin_link
  end

end
