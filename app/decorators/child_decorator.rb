class ChildDecorator < BaseDecorator

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

  def admin_link(options = {})
    super(options.merge(class: GENDER_COLORS[safe_gender.to_sym]))
  end

  def public_edit_url
    h.edit_child_url(id: model.id, security_code: model.security_code)
  end

  def public_edit_link(options = {})
    url = public_edit_url
    txt = options.delete(:label) || url
    h.link_to txt, url, options
  end

  def child_present_on
    model.child_support&.decorate&.children_present_on
  end

  def child_follow_us_on
    model.child_support&.decorate&.children_follow_us_on
  end

  def age
    h.t "child_age.months", months: model.months
  end

  def age_in_months_or_years
    months = model.months
    if months < 24
      h.t "child_age.months", months: months
    else
      h.t "child_age.years", years: (months / 12).floor
    end
  end

  def birthdate
    h.l model.birthdate, format: :default
  end

  def safe_gender
    model.gender.presence || "x"
  end

  def gender_status
    arbre do
      status_tag gender, class: GENDER_COLORS[safe_gender.to_sym]
    end
  end

  def gender
    Child.human_attribute_name("gender.#{safe_gender}")
  end

  def group_status
    if v = model.group_status
      Child.human_attribute_name("group_status.#{v}")
    end
  end

  def gendered_name_with_age(options = {})
    with_icon = options.delete(:with_icon)

    txt = options.delete(:label) || name
    if with_icon
      txt = h.content_tag(:i, "", class: "fas fa-#{icon_class}") + "&nbsp;".html_safe + txt
    end
    h.content_tag :span do
      h.content_tag(:span, txt, {class: "txt-#{GENDER_COLORS[safe_gender.to_sym]}"}.merge(options))
      + " (" + age + ")"
    end
  end

  def name
    [model.first_name, model.last_name].join " "
  end

  def parent1
    parent decorated_parent1, model.should_contact_parent1?
  end

  def parent2
    parent decorated_parent2, model.should_contact_parent2?
  end

  def parent1_gender
    parent_attribute decorated_parent1, :gender
  end

  def parent2_gender
    parent_attribute decorated_parent2, :gender
  end

  def group
    options = {}
    if model.group_status == "stopped"
      options[:class] = "stop"
    elsif model.group_status == "paused"
      options[:class] = "pause"
    elsif model.group_status == "waiting"
      options[:class] = "wait"
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

  # def family_text_messages_count
  #   model.family_text_messages.kept.count
  # end

  def family_text_messages_received_count
    model.family_text_messages_received.kept.count
  end

  def family_text_messages_sent_count
    model.family_text_messages_sent.kept.count
  end

  def full_address
    model.parent1.decorate.full_address
  end

  def child_group_name
    model.group&.name
  end

  def pmi_detail
    return nil if model.pmi_detail.blank?
    Child.human_attribute_name("pmi_detail.#{model.pmi_detail}")
  end

  def registration_months_range
    return unless registration_months

    if registration_months >= 36
      "Plus de 36 mois"
    elsif registration_months >= 24
      "24 - 36 mois"
    elsif registration_months >= 12
      "12 - 24 mois"
    elsif registration_months >= 6
      "6 - 12 mois"
    else
      "Moins de 6 mois"
    end
  end

  private

  def decorated_parent1
    @decorated_parent1 ||= model.parent1&.decorate
  end

  def decorated_parent2
    @decorated_parent2 ||= model.parent2&.decorate
  end

  def parent(decorated_parent, should_contact_parent)
    return nil unless decorated_parent
    options = {}
    options[:class] = "txt-underline" if should_contact_parent
    decorated_parent.admin_link(options)
  end

  def parent_attribute(decorated_parent, key)
    decorated_parent&.send(key)
  end

end
