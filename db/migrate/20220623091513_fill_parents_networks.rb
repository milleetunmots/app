class FillParentsNetworks < ActiveRecord::Migration[6.0]
  def up
    ChildSupport.all.each do |child_support|
      child_support.parent1&.update! follow_us_on_facebook: true if child_support.follow_us_on&.include?("Facebook national")
      child_support.parent2&.update! follow_us_on_facebook: true if child_support.follow_us_on&.include?("Facebook national")

      child_support.parent1&.update! follow_us_on_facebook: true if child_support.follow_us_on&.include?("Facebook local")
      child_support.parent2&.update! follow_us_on_facebook: true if child_support.follow_us_on&.include?("Facebook local")

      child_support.parent1&.update! follow_us_on_whatsapp: true if child_support.follow_us_on&.include?("WhatsApp")
      child_support.parent2&.update! follow_us_on_whatsapp: true if child_support.follow_us_on&.include?("WhatsApp")

      child_support.parent1&.update! present_on_facebook: true if child_support.present_on&.include?("Facebook")
      child_support.parent2&.update! present_on_facebook: true if child_support.present_on&.include?("Facebook")

      child_support.parent1&.update! present_on_whatsapp: true if child_support.present_on&.include?("WhatsApp")
      child_support.parent2&.update! present_on_whatsapp: true if child_support.present_on&.include?("WhatsApp")
    end
  end

  def down

  end
end
