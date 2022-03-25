class FamilyDecorator < BaseDecorator

  def parent1
    model.parent1&.decorate&.name
  end

  def parent2
    model.parent2&.decorate&.name
  end

  def children
    arbre do
      ul do
        model.children.each do |child|
          li do
            child.decorate&.name
          end
        end
      end
    end
  end

end
