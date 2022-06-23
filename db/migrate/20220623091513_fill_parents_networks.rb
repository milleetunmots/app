class FillParentsNetworks < ActiveRecord::Migration[6.0]
  def change
    ChildSupport.all.each do |child_support|
      child_support.parent1.update! on_facebook: true if child_support.follow_us_on.include?("Facebook national")
      child_support.parent2&.update! on_facebook: true if child_support.follow_us_on.include?("Facebook national")

      child_support.parent1.update! on_facebook: true if child_support.follow_us_on.include?("Facebook local")
      child_support.parent2&.update! on_facebook: true if child_support.follow_us_on.include?("Facebook local")

      child_support.parent1.update! on_whatsapp: true if child_support.follow_us_on.include?("WhatsApp")
      child_support.parent2&.update! on_whatsapp: true if child_support.follow_us_on.include?("WhatsApp")
    end
  end
end
