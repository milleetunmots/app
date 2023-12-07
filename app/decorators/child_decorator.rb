class ChildDecorator < BaseDecorator

  GENDER_COLORS = { m: :blue, f: :rose, x: :grey }.freeze

  GENDER_CLASSES = { m: :male, f: :female, x: :unknown }.freeze

  def admin_link(options = {})
    super(options.merge(class: GENDER_COLORS[safe_gender.to_sym]))
  end

  def child_link
    options = { with_icon: true, target: '_blank' }
    txt = h.content_tag(:i, '', class: "fas fa-#{icon_class}") + "&nbsp;".html_safe + name
    is_current_child = model.current_child?
    txt = txt + '&nbsp;'.html_safe + h.content_tag(:i, '', class: 'fas fa-sms') if is_current_child
    txt = txt + '&nbsp;'.html_safe + h.content_tag(:i, '', class: 'fas fa-book') if model.group_status == 'active'
    options[:title] = if is_current_child && model.group_status == 'active'
                        'Les SMS sont envoyés pour moi et je reçois les livres'
                      elsif is_current_child
                        'Les SMS sont envoyés pour moi'
                      elsif model.group_status == 'active'
                        'Je reçois les livres'
                      end
    options[:class] = [
      options[:class],
      model.respond_to?(:discarded?) && (model.discarded? ? 'discarded' : 'kept'),
      options[:class],
      GENDER_COLORS[safe_gender.to_sym]
    ].compact.join(' ')
    h.link_to txt, [:admin, model], options
  end

  def public_edit_url
    h.edit_child_url(id: model.id, security_code: model.security_code)
  end

  def public_edit_link(options = {})
    url = public_edit_url
    txt = options.delete(:label) || url
    h.link_to txt, url, options
  end

  def age
    h.t 'child_age.months', months: model.months
  end

  def age_in_months_or_years
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

  def safe_gender
    model.gender.presence || 'x'
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
    return unless model.group_status

    Child.human_attribute_name("group_status.#{model.group_status}")
  end

  def gendered_name_with_age(options = {})
    with_icon = options.delete(:with_icon)
    txt = options.delete(:label) || name
    txt = h.content_tag(:i, "", class: "fas fa-#{icon_class}") + "&nbsp;".html_safe + txt if with_icon

    h.content_tag :span do
      h.content_tag(:span, txt, { class: "txt-#{GENDER_COLORS[safe_gender.to_sym]}" }.merge(options))
      + " (" + age + ")"
    end
  end

  def name
    [model.first_name, model.last_name].join ' '
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
    case model.group_status
    when 'stopped'
      options[:class] = 'stop'
    when 'paused'
      options[:class] = 'pause'
    when 'waiting'
      options[:class] = 'wait'
    end
    model.group&.decorate&.admin_link(options)
  end

  def source
    return unless model.source

    model.source.decorate.name
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

  def family_text_messages_count
    model.family_text_messages.kept.count
  end

  def family_text_messages_received_count
    model.family_text_messages_received.kept.count
  end

  def family_text_messages_sent_count
    model.family_text_messages_sent.kept.count
  end

  def full_address
    model.parent1.decorate.full_address
  end

  def address_with_letterbox_name
    [letterbox_name, address].reject(&:blank?).join(' ')
  end

  def child_group_name
    model.group&.name
  end

  def registration_months_range
    return unless registration_months

    if registration_months >= 37
      'Plus de 36 mois'
    elsif registration_months >= 25
      '25 à 36 mois'
    elsif registration_months >= 13
      '13 à 24 mois'
    elsif registration_months >= 7
      '7 - 12 mois'
    else
      'Moins de 6 mois'
    end
  end

  def selected_support_module_list
    arbre do
      ChildrenSupportModule.where(child: model).where.not(support_module: nil).each do |children_support_module|
        span children_support_module.support_module&.name,
             class: 'available_support_module'
        text_node '&nbsp;'.html_safe
      end
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
