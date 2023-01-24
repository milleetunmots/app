class ApplicationRecord < ActiveRecord::Base

  REGEX_VALID_NAME = /\A[^0-9`!@#\$%\^&*+_=]+\z/
  REGEX_VALID_ADDRESS = /\A[^`!@#\$%\^&*+_=]+\z/
  REGEX_VALID_EMAIL = /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
  INVALID_NAME_MESSAGE = "ne doit pas contenir des caractères spéciaux ou des chiffres"
  INVALID_ADDRESS_MESSAGE = "ne doit pas contenir des caractères spéciaux"

  self.abstract_class = true

  # ---------------------------------------------------------------------------
  # tags
  # ---------------------------------------------------------------------------

  def self.tagged_with_all(*v)
    tagged_with(v)
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
end
