class WorkshopDecorator < BaseDecorator

  def workshop_address
    "#{address} #{postal_code} #{city_name}"
  end

  def workshop_parents_list
    parents = parents_list
    arbre do
      ul do
        parents.each do |parent|
          li do
            parent.decorate.admin_link
          end
        end
      end
    end
  end

  private

  def parents_list
    Parent.find(parents_selected.map(&:to_i))
  end
end
