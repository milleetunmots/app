class ApplicationRecord < ActiveRecord::Base

  REGEX_VALID_NAME = /\A[^0-9`!@#\$%\^&*+_=]+\z/.freeze
  REGEX_VALID_ADDRESS = /\A[^`!@#\$%\^&*+_=]+\z/.freeze
  REGEX_VALID_EMAIL = /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i.freeze
  INVALID_NAME_MESSAGE = 'ne doit pas contenir des caractères spéciaux ou des chiffres'.freeze
  INVALID_ADDRESS_MESSAGE = 'ne doit pas contenir des caractères spéciaux'.freeze

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
end
