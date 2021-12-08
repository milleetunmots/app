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
    parents_tagged = Parent.tagged_with(guests_tag).pluck(:id).map(&:to_i)
    guest_list = (parents_selected + parents_tagged).uniq
    Parent.find(guest_list.map(&:to_i))
  end
end
