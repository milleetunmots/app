class ParentDecorator < BaseDecorator

  GENDER_COLORS = {
    m: :blue,
    f: :rose
  }

  def admin_link(options = {})
    super(options.merge(class: GENDER_COLORS[model.gender.to_sym]))
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

  def full_address
    attention_to = model.attention_to&.gsub('Pour', "A l'attention de")
    full_address =
      case model.book_delivery_location
      when 'home'
        [letterbox_name, address]
      when 'relative_home'
        [letterbox_name, attention_to, address]
      else
        [book_delivery_organisation_name, attention_to, address]
      end
    full_address << address_supplement if address_supplement.present?
    full_address << [postal_code, city_name].join(' ')
    full_address.join('<br/>').html_safe
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
            div do
              a display_selected_module,
                href: admin_children_support_module_path(children_support_module),
                class: 'available_support_module',
                target: '_blank'
              text_node "&nbsp;".html_safe
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
end
