class ParentDecorator < BaseDecorator

  def admin_link(options = {})
    with_icon = options.delete(:with_icon)

    txt = name
    if with_icon
      txt = h.content_tag(:i, '', class: "fas fa-#{icon_class}") + "&nbsp;".html_safe + txt
    end
    options[:class] = [options[:class], GENDER_COLORS[model.gender.to_sym]].compact.join(' ')
    h.link_to txt, [:admin, model], options
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

  def email
    h.mail_to model.email
  end

  GENDER_COLORS = {
    m: :blue,
    f: :rose
  }

  def gender
    arbre do
      status_tag gender_text, class: GENDER_COLORS[model.gender.to_sym]
    end
  end

  def gender_text
    Parent.human_attribute_name("gender.#{model.gender}")
  end

  def name
    [model.first_name, model.last_name].join ' '
  end

  def phone_number
    phone = Phonelib.parse model.phone_number
    phone.national
  end

  def full_address
    [
      letterbox_name,
      address,
      [
        postal_code,
        city_name
      ].join(' ')
    ].join('<br/>').html_safe
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

  private

  def child(child)
    h.link_to child.decorate.name, [:admin, child], class: ChildDecorator::GENDER_COLORS[child.gender.to_sym]
  end
end
