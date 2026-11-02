class ParentDecorator < BaseDecorator

  GENDER_COLORS = {
    m: :blue,
    f: :rose
  }

  # La fiche de l'enfant courant, comme pour le reste de la fiche parent
  def ok_for_solicitation
    model.current_child&.child_support&.ok_for_solicitation
  end

  def admin_link(options = {})
    child_support_id = options.delete(:child_support_id)
    link_options = options.merge(class: GENDER_COLORS[model.gender.to_sym])
    return super(link_options) if child_support_id.blank?

    # Le nom est isolé dans un span sécable : lui seul peut se couper en bout de
    # ligne, les icônes restent solidaires du dernier fragment (cf. cards.sass).
    name_link = super(link_options.merge(label: h.content_tag(:span, name, class: 'name-text')))
    icon = '&nbsp;'.html_safe + h.content_tag(:i, '', class: 'fa-solid fa-pencil')
    h.content_tag(:span, class: 'name-with-edit') do
      name_link +
        h.link_to(
          icon,
          h.edit_admin_parent_path(model, back_to_child_support_id: child_support_id),
          class: 'js-save-before-leave'
        )
    end
  end

  def children
    arbre do
      ul do
        model.children.decorate.each do |child|
          li child.admin_link
        end
      end
    end
  end

  def children_count
    model.children.count
  end

  def email_link
    h.mail_to model.email
  end

  def gender_status
    arbre do
      status_tag gender, class: GENDER_COLORS[model.gender.to_sym]
    end
  end

  def gender
    Parent.human_attribute_name("gender.#{model.gender}")
  end

  def name
    [model.first_name, model.last_name].join ' '
  end

  def phone_number(with_icon: false)
    return nil if model.phone_number.blank?

    phone = Phonelib.parse model.phone_number
    r = if model.should_be_contacted?
          [phone.national]
        else
          [h.content_tag(:span, phone.national, style: 'text-decoration: line-through;')]
        end
    if with_icon
      r << h.image_tag('whatsapp.png', class: 'phone-number-icon') if model.follow_us_on_whatsapp?
    end
    r.join.html_safe
  end

  # Longueur max d'une ligne d'étiquette. L'AFNOR recommande 38 caractères ; au-delà
  # il s'agit de texte libre saisi par le parent, qui pousserait la dernière ligne
  # (code postal + ville) hors de l'étiquette de 44 mm.
  LABEL_LINE_MAX_LENGTH = 44

  # Zone utile des étiquettes Agipa 119006 de 70 × 35 mm, marge intérieure retirée
  # (cf. pdf.sass) : 64 × 30 mm, en points (1 pt = 1/72 pouce).
  LABEL_USABLE_WIDTH_PT = 64 / 25.4 * 72 # 181.4
  LABEL_USABLE_HEIGHT_PT = 30 / 25.4 * 72 # 85.0

  # Largeur moyenne d'un caractère, en em : 9e décile mesuré sur des adresses réelles,
  # à partir des largeurs d'avance des TTF de app/assets/fonts (le même calcul sur
  # Nunito redonne les 26 caractères de l'ancien calibrage).
  LABEL_BODY_EM_PER_CHAR = 0.544 # Poppins Regular
  LABEL_HEADING_EM_PER_CHAR = 0.592 # Fredoka Bold

  # Titre : 1.45em de la taille du corps, interligne 1.2 (cf. .address-heading de pdf.sass)
  LABEL_HEADING_SCALE = 1.45
  LABEL_HEADING_LINE_HEIGHT = 1.2

  # [taille du corps en pt, interligne du corps en pt, classe CSS], du plus grand au
  # plus petit, comme dans pdf.sass. Capacité qui en découle : 1 titre + 3 lignes de
  # corps au palier maximal, 1 + 4 au palier réduit, 1 + 6 au plus petit.
  # À reprendre si la taille des étiquettes, les paddings ou les polices changent.
  LABEL_FONT_TIERS = [
    [13, 18, nil],
    [10, 14, 'address-content--small'],
    [8, 11, 'address-content--tiny']
  ].freeze

  # upcase: false garde la casse saisie (étiquettes) ; la fiche de suivi et la
  # variable SMS {PARENT_ADDRESS} restent en majuscules.
  def address_lines(upcase: true)
    name = delivery_name.to_s
    attention_to = model.attention_to
    if upcase
      name = name.upcase
      attention_to = attention_to&.upcase
    end
    attention_to = attention_to&.sub(/\Apour\b/i, "A l'attention de")
    lines = [name]
    lines << attention_to unless model.book_delivery_location == 'home'
    lines << address
    lines << address_supplement if address_supplement.present?
    lines << [postal_code, city_name].join(' ')
    lines.compact_blank
  end

  def full_address(separator = '<br/>')
    address_lines.join(separator).html_safe
  end

  def label_address_lines
    address_lines(upcase: false).map { |line| line.squish.truncate(LABEL_LINE_MAX_LENGTH) }
  end

  # 1re ligne de l'étiquette, mise en avant : nom sur la boîte aux lettres ou raison
  # sociale. nil quand ce nom manque (donnée ancienne) : address_lines l'a alors
  # retiré, et aucune ligne d'adresse ne doit prendre sa place en titre.
  def label_heading_line
    label_address_lines.first if delivery_name.present?
  end

  def label_body_lines
    label_heading_line ? label_address_lines.drop(1) : label_address_lines
  end

  # Réduit la police quand l'adresse ne tient pas dans l'étiquette, pour que la
  # dernière ligne (code postal + ville) reste toujours visible.
  def label_size_class
    tier = LABEL_FONT_TIERS.find { |size, line_height, _css_class| label_height_pt(size, line_height) <= LABEL_USABLE_HEIGHT_PT }
    (tier || LABEL_FONT_TIERS.last).last
  end

  def icon_class
    model.gender.to_sym == :m ? :male : :female
  end

  def as_autocomplete_result
    h.content_tag :div, class: "parent #{model.gender.to_sym == :m ? :male : :female}" do
      (
        h.content_tag :div, class: :name do
          name
        end
      ) + (
        h.content_tag :div do
          (
            h.content_tag :span, class: :email do
              model.email
            end
          ) + (
            h.content_tag :span, class: 'phone-number' do
              phone_number
            end
          )
        end
      )
    end
  end

  def redirection_urls_count
    model.redirection_urls_count || 0
  end

  def redirection_visit_rate
    return nil if redirection_urls_count.zero?
    h.number_to_percentage(model.redirection_visit_rate * 100, precision: 0)
  end

  def redirection_unique_visit_rate
    return nil if redirection_urls_count.zero?
    h.number_to_percentage(model.redirection_unique_visit_rate * 100, precision: 0)
  end

  def redirection_visits
    return nil if redirection_urls_count.zero?
    "#{model.redirection_url_visits_count} (#{redirection_visit_rate})"
  end

  def redirection_unique_visits
    return nil if redirection_urls_count.zero?
    "#{model.redirection_url_unique_visits_count}/#{redirection_urls_count} (#{redirection_unique_visit_rate})"
  end

  def text_messages_count
    model.events.text_messages.kept.count
  end

  def parent_groups
    model.children.decorate.map(&:group_name).join("\n")
  end

  def selected_support_module
    arbre do
      model.children_support_modules.includes(:support_module).decorate.group_by(&:child_id).each do |_, children_support_modules|
        div(style: 'margin-bottom: 10px;') do
          children_support_modules.each do |children_support_module|
            display_selected_module = "#{children_support_module.name} - #{children_support_module.created_at.strftime("%d/%m/%Y")}"
            display_selected_module = "#{display_selected_module} - #{children_support_module.child.first_name}" if children_support_module.child.have_siblings_on_same_group?
            airtable_url = children_support_module.support_module&.decorate&.airtable_folder_url
            div do
              a display_selected_module,
                href: admin_children_support_module_path(children_support_module),
                class: 'available_support_module',
                target: '_blank'
              text_node "&nbsp;".html_safe
              # accès direct au contenu du module sur Airtable
              if airtable_url
                a href: airtable_url,
                  target: '_blank',
                  rel: 'noopener',
                  class: 'support-module-airtable-link',
                  title: 'Ouvrir le contenu du module sur Airtable' do
                  i class: 'fas fa-external-link-alt'
                end
              end
            end
          end
        end
      end
    end
  end

  def book_delivery_location_name
    Parent.human_attribute_name("book_delivery_location.#{model.book_delivery_location}")
  end

  private

  def child(child)
    h.link_to child.decorate.name, [:admin, child], class: ChildDecorator::GENDER_COLORS[child.gender.to_sym]
  end

  # Hauteur de l'étiquette rendue au palier donné : chaque ligne occupe autant de
  # lignes rendues que sa longueur l'impose, le titre avec sa taille et son interligne
  def label_height_pt(size, line_height)
    heading_size = size * LABEL_HEADING_SCALE
    body_rows = label_body_lines.sum { |line| label_rows(line, size * LABEL_BODY_EM_PER_CHAR) }
    heading_rows = label_heading_line ? label_rows(label_heading_line, heading_size * LABEL_HEADING_EM_PER_CHAR) : 0

    (heading_rows * heading_size * LABEL_HEADING_LINE_HEIGHT) + (body_rows * line_height)
  end

  def label_rows(line, char_width_pt)
    [(line.length / (LABEL_USABLE_WIDTH_PT / char_width_pt)).ceil, 1].max
  end

  # Nom en tête de l'adresse : la boîte aux lettres pour un domicile (le sien ou
  # celui d'un proche), la raison sociale pour une structure
  def delivery_name
    model.book_delivery_location.in?(%w[home relative_home]) ? letterbox_name : book_delivery_organisation_name
  end
end
