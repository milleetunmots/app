class UpdateLandTagsToChildren < ActiveRecord::Migration[6.0]
  def up
    Child.tagged_with("Paris_18_eme").each do |child|
      child.land_list.add("Paris 18 eme")
      child.tag_list.remove("Paris_18_eme")
      child.save!
    end

    Child.tagged_with("Paris_20_eme").each do |child|
      child.land_list.add("Paris 20 eme")
      child.tag_list.remove("Paris_20_eme")
      child.save!
    end

    Child.tagged_with("Plaisir").each do |child|
      child.land_list.add("Plaisir")
      child.tag_list.remove("Plaisir")
      child.save!
    end

    Child.tagged_with("Trappes").each do |child|
      child.land_list.add("Trappes")
      child.tag_list.remove("Trappes")
      child.save!
    end

    Child.tagged_with("Les Clayes Sous Bois").each do |child|
      child.land_list.add("Les Clayes Sous Bois")
      child.tag_list.remove("Les Clayes Sous Bois")
      child.save!
    end

    Child.tagged_with("Coignière, Maurepas").each do |child|
      child.land_list.add("Coignière, Maurepas")
      child.tag_list.remove("Coignière, Maurepas")
      child.save!
    end

    Child.tagged_with("Elancourt").each do |child|
      child.land_list.add("Elancourt")
      child.tag_list.remove("Elancourt")
      child.save!
    end

    Child.tagged_with("Guyancourt").each do |child|
      child.land_list.add("Guyancourt")
      child.tag_list.remove("Guyancourt")
      child.save!
    end

    Child.tagged_with("Montigny le bretonneux").each do |child|
      child.land_list.add("Montigny le bretonneux")
      child.tag_list.remove("Montigny le bretonneux")
      child.save!
    end

    Child.tagged_with("La verrière").each do |child|
      child.land_list.add("La verrière")
      child.tag_list.remove("La verrière")
      child.save!
    end

    Child.tagged_with("Voisin le Bretonneux").each do |child|
      child.land_list.add("Voisin le Bretonneux")
      child.tag_list.remove("Voisin le Bretonneux")
      child.save!
    end

    Child.tagged_with("Villepreux").each do |child|
      child.land_list.add("Villepreux")
      child.tag_list.remove("Villepreux")
      child.save!
    end

    Child.tagged_with("Aulnay-Sous-Bois").each do |child|
      child.land_list.add("Aulnay-Sous-Bois")
      child.tag_list.remove("Aulnay-Sous-Bois")
      child.save!
    end

    Child.tagged_with("Orleans").each do |child|
      child.land_list.add("Orleans")
      child.tag_list.remove("Orleans")
      child.save!
    end

    Child.tagged_with("Montargis").each do |child|
      child.land_list.add("Montargis")
      child.tag_list.remove("Montargis")
      child.save!
    end
  end
end
