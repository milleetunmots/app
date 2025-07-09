class ApplicationRecord < ActiveRecord::Base

  REGEX_VALID_NAME = /\A[^0-9`!@#\$%\^&*+_=]+\z/.freeze
  REGEX_VALID_ADDRESS = /\A[^`!@#\$%\^&*+_=]+\z/.freeze
  REGEX_VALID_EMAIL = /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i.freeze
  REGEX_VALID_PASSWORD = /\A(?=.*\d)(?=.*[a-z])(?=.*[[:^alnum:]])/x.freeze
  INVALID_NAME_MESSAGE = 'ne doit pas contenir des caractères spéciaux ou des chiffres'.freeze
  INVALID_ADDRESS_MESSAGE = 'ne doit pas contenir des caractères spéciaux'.freeze
  INVALID_PASSWORD_MESSAGE = 'doit contenir au moins un chiffre, une lettre et un caractère spécial'.freeze

  self.abstract_class = true

  # ---------------------------------------------------------------------------
  # tags
  # ---------------------------------------------------------------------------

  def self.tagged_with_all(*tags)
    tagged_with(tags)
  end

  # ---------------------------------------------------------------------------
  # ransack
  # ---------------------------------------------------------------------------

  def self.ransackable_scopes(auth_object = nil)
    %i[tagged_with_all]
  end

  def self.ransackable_scopes_skip_sanitize_args
    ransackable_scopes
  end

  def old_tag_list
    return unless tag_list_changed?

    tag_list_change.first
  end

  def new_tag_list
    return unless tag_list_changed?

    tag_list_change.last
  end

  def tags_to_add
    new_tag_list.to_a - old_tag_list.to_a
  end

  def tags_to_remove
    old_tag_list.to_a - new_tag_list.to_a
  end

  def distribute_tags_to(element)
    element.tag_list.add(tags_to_add) if tags_to_add.present?
    element.tag_list.remove(tags_to_remove) if tags_to_remove.present?
    element.save(validate: false)
  end

  def distribute_tags_to_parents
    return unless parent1
    return unless tag_list_changed?

    distribute_tags_to(parent1)
    return unless parent2

    distribute_tags_to(parent2)
  end

  def distribute_tags_to_children
    return if children.blank?
    return unless tag_list_changed?

    children.each do |child|
      distribute_tags_to(child)
    end
  end
end
