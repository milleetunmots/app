class FillParentsNetworksWithChildSupportTags < ActiveRecord::Migration[6.0]
  def change
    ChildSupport.tagged_with("facebook").each do |child_support|
      child_support.parent1.update! present_on_facebook: true
      child_support.parent1.update! follow_us_on_facebook: true
      child_support.parent2&.update! present_on_facebook: true
      child_support.parent2&.update! follow_us_on_facebook: true
    end

    ChildSupport.tagged_with("Whatsapp").each do |child_support|
      child_support.parent1.update! present_on_whatsapp: true
      child_support.parent1.update! follow_us_on_whatsapp: true
      child_support.parent2&.update! present_on_whatsapp: true
      child_support.parent2&.update! follow_us_on_whatsapp: true
    end
  end
end
