class ChildDecorator < BaseDecorator

  def admin_link(options = {})
    with_icon = options.delete(:with_icon)

    txt = options.delete(:label) || name
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
      status_tag gender_text, class: GENDER_COLORS[safe_gender.to_sym]
    end
  end

  def gender_text
    Child.human_attribute_name("gender.#{safe_gender}")
  end

  def name
    [model.first_name, model.last_name].join ' '
  end

  def parent1
    parent model.parent1, model.should_contact_parent1?
  end

  def parent2
    parent model.parent2, model.should_contact_parent2?
  end

  def group
    options = {}
    if model.has_quit_group?
      options[:class] = 'quit'
    end
    model.group&.decorate&.admin_link(options)
  end

  def registration_source
    if v = model.registration_source
      Child.human_attribute_name("registration_source.#{v}")
    end
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

  def family_redirection_urls_count
    model.family_redirection_urls_count || 0
  end

  def family_redirection_visit_rate
    return nil if family_redirection_urls_count.zero?
    h.number_to_percentage(model.family_redirection_visit_rate * 100, precision: 0)
  end

  def family_redirection_unique_visit_rate
    return nil if family_redirection_urls_count.zero?
    h.number_to_percentage(model.family_redirection_unique_visit_rate * 100, precision: 0)
  end

  def family_redirection_visits
    return nil if family_redirection_urls_count.zero?
    "#{model.family_redirection_url_visits_count}/#{family_redirection_urls_count} (#{family_redirection_visit_rate})"
  end

  def family_redirection_unique_visits
    return nil if family_redirection_urls_count.zero?
    "#{model.family_redirection_url_unique_visits_count}/#{family_redirection_urls_count} (#{family_redirection_unique_visit_rate})"
  end

  private

  def parent(parent, should_contact_parent)
    return nil unless parent
    options = {}
    options[:class] = 'txt-underline' if should_contact_parent
    parent.decorate.admin_link(options)
  end

end
