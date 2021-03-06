class ParentDecorator < BaseDecorator

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

  GENDER_COLORS = {
    m: :blue,
    f: :rose
  }

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
    phone = Phonelib.parse model.phone_number
    r = [phone.national]
    if with_icon
      if model.is_lycamobile?
        r << h.image_tag('lycamobile.png', class: 'phone-number-icon')
      end
    end
    r.join.html_safe
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

  def text_messages_count
    model.events.text_messages.kept.count
  end

  private

  def child(child)
    h.link_to child.decorate.name, [:admin, child], class: ChildDecorator::GENDER_COLORS[child.gender.to_sym]
  end
end
