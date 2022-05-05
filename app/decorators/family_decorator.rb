class FamilyDecorator < BaseDecorator

  def admin_link
    h.auto_link model
  end

  def parent1
    @decorated_parent1 ||= model.parent1&.decorate&.admin_link
  end

  def parent2
    @decorated_parent2 ||= model.parent2&.decorate&.admin_link
  end

  def children
    arbre do
      ul do
        model.children.decorate.each do |child|
          li do
            child.admin_link
          end
        end
      end
    end
  end

  def parent1_name
    model.parent1.decorate.name
  end

  def parent2_name
    model.parent2&.decorate&.name
  end

  def full_address
    [
      letterbox_name,
      address,
      [
        postal_code,
        city_name
      ].join(' ')
    ].join("\n")
  end

  def all_children
    result = []
    model.children.to_a.each {|child| result << child.decorate.name }
    result.join("\n")
  end
end
