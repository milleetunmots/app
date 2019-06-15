class ParentDecorator < BaseDecorator

  def admin_link
    h.link_to name, [:admin, model], class: GENDER_COLORS[model.gender.to_sym]
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
      status_tag Parent.human_attribute_name("gender.#{model.gender}"), class: GENDER_COLORS[model.gender.to_sym]
    end
  end

  def name
    [model.first_name, model.last_name].join ' '
  end

  def phone_number
    phone = Phonelib.parse model.phone_number
    phone.national
  end

  private

  def child(child)
    h.link_to child.decorate.name, [:admin, child], class: ChildDecorator::GENDER_COLORS[child.gender.to_sym]
  end
end
