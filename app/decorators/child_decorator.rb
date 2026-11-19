class ChildDecorator < BaseDecorator

  # Pastille de genre (status_tag) : fond rose ou bleu clair
  GENDER_TAG_COLORS = { m: :blue, f: :rose, x: :grey }.freeze

  # Teinte de genre du prénom et de son icône (cf. BaseDecorator#name_link_classes)
  GENDER_MODIFIERS = { m: 'boy', f: 'girl', x: nil }.freeze

  GENDER_CLASSES = { m: :male, f: :female, x: :unknown }.freeze

  # Largeur utile du prénom sur l'étiquette cadeau : cartouche de 41,6 mm, moins
  # 1,75 + 3,55 mm de padding et 2 × 0,53 mm de bordure (cf. pdf.sass), en points
  GIFT_NAME_WIDTH_PT = 35.2 / 25.4 * 72 # 99.8

  # [taille du prénom en pt, classe CSS], du plus grand au plus petit, comme dans
  # pdf.sass ; 12,5 pt est la taille de la maquette. Le prénom prend le plus grand
  # palier où il tient sur une ligne, mesuré sur les glyphes de Fredoka Bold.
  GIFT_NAME_FONT_TIERS = [
    [12.5, nil],
    [11, 'gift-card-name--small'],
    [9, 'gift-card-name--tiny'],
    [7.5, 'gift-card-name--micro']
  ].freeze

  # Prénom teinté selon le genre (name-link--boy / --girl)
  def admin_link(options = {})
    super(options.merge(class: [options[:class], *name_link_classes].compact.join(' ')))
  end

  def gender_modifier
    GENDER_MODIFIERS[safe_gender.to_sym]
  end

  def ok_for_solicitation
    model.child_support&.ok_for_solicitation
  end

  def child_link(child_support_id: nil)
    options = { with_icon: true, target: '_blank' }
    # Le nom est isolé dans un span sécable : lui seul peut se couper en bout de
    # ligne, les icônes restent solidaires du dernier fragment (cf. cards.sass).
    txt = gender_icon + '&nbsp;'.html_safe + h.content_tag(:span, name, class: 'name-text')
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
      *name_link_classes,
      options[:class],
      model.respond_to?(:discarded?) && (model.discarded? ? 'discarded' : 'kept')
    ].compact.join(' ')
    return h.link_to(txt, [:admin, model], options) if child_support_id.blank?

    icon = '&nbsp;'.html_safe + h.content_tag(:i, '', class: 'fa-solid fa-pencil', aria: { hidden: true })
    h.content_tag(:span, class: 'name-with-edit') do
      h.link_to(txt, [:admin, model], options) +
        h.link_to(
          icon,
          h.edit_admin_child_path(model, back_to_child_support_id: child_support_id),
          class: 'js-save-before-leave',
          # Icône seule : le lien est nommé pour les lecteurs d'écran
          title: 'Modifier',
          aria: { label: "Modifier #{name}" }
        )
    end
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
      status_tag gender, class: GENDER_TAG_COLORS[safe_gender.to_sym]
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
    txt = gender_icon + '&nbsp;'.html_safe + txt if with_icon
    h.content_tag :span do
      h.content_tag(:span, txt, options) + ' (' + age + ')'
    end
  end

  def name
    [model.first_name, model.last_name].join ' '
  end

  def parent1
    decorated_parent1&.admin_link
  end

  def parent2
    decorated_parent2&.admin_link
  end

  def parent1_gender
    parent_attribute decorated_parent1, :gender
  end

  def parent2_gender
    parent_attribute decorated_parent2, :gender
  end

  def group
    options = {}
    if %w[stopped disengaged].include? model.group_status
      options[:class] = 'stop'
    elsif %w[not_supported paused].include? model.group_status
      options[:class] = 'pause'
    elsif model.group_status == 'waiting'
      options[:class] = 'wait'
    end
    model.group&.decorate&.admin_link(options)
  end

  def source
    return unless model.source

    model.source.decorate.name
  end

  def source_details
    return unless model.children_source&.details

    model.children_source.details
  end

  def channel
    return unless model.source

    model.source.decorate.channel
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

  def label_address_lines
    model.parent1.decorate.label_address_lines
  end

  def label_heading_line
    model.parent1.decorate.label_heading_line
  end

  def label_body_lines
    model.parent1.decorate.label_body_lines
  end

  def label_size_class
    model.parent1.decorate.label_size_class
  end

  def label_heading_class
    model.parent1.decorate.label_heading_class
  end

  # Réduit le prénom de l'étiquette cadeau pour qu'il tienne sur une ligne
  def gift_name_size_class
    width_em = LabelTextLayout.width_em(model.first_name, 'fredoka-bold')
    tier = GIFT_NAME_FONT_TIERS.find { |size, _css_class| width_em * size <= GIFT_NAME_WIDTH_PT }
    (tier || GIFT_NAME_FONT_TIERS.last).last
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

  def parent_attribute(decorated_parent, key)
    decorated_parent&.send(key)
  end
end
