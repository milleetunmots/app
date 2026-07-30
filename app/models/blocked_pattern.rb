# == Schema Information
#
# Table name: blocked_patterns
#
#  id               :bigint           not null, primary key
#  kind             :string           not null
#  normalized_value :string           not null
#  value            :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_blocked_patterns_on_kind_and_normalized_value  (kind,normalized_value) UNIQUE
#
class BlockedPattern < ApplicationRecord

  KINDS = %w[keyword].freeze

  before_validation :compute_normalized_value

  validates :kind, inclusion: { in: KINDS }
  validates :value, presence: true
  validate :normalized_value_has_minimum_alphanumerics
  validates :normalized_value, uniqueness: { scope: :kind, message: 'existe déjà sous une autre graphie' }

  # Une seule implémentation de normalisation, partagée entre les patterns
  # (à la sauvegarde) et le texte scanné (au moment du contrôle).
  #
  # Les espaces Unicode (ex. insécable, naturel avant « ! » « ? » « : » en
  # typographie française) et les apostrophes typographiques doivent être
  # uniformisés AVANT `transliterate` : celui-ci ne sait traiter que de
  # l'ASCII et remplace tout le reste par "?", ce qui casse silencieusement
  # la normalisation (un espace insécable devient "?" au lieu de fusionner).
  # `[[:space:]]` est Unicode-aware, contrairement à `\s` qui ne couvre que
  # l'ASCII.
  def self.normalize(text)
    pre_normalized = text.to_s.gsub(/[[:space:]]+/, ' ').tr('’‘', "''")
    ActiveSupport::Inflector.transliterate(pre_normalized).downcase.gsub(/\s+/, ' ').strip
  end

  # Frontières de mots : « carte » ne matche pas « écarter ».
  def self.regex_for(normalized_value)
    /(?<![[:alnum:]])#{Regexp.escape(normalized_value)}(?![[:alnum:]])/
  end

  def matches_normalized?(normalized_text)
    return false if normalized_text.blank?

    self.class.regex_for(normalized_value).match?(normalized_text)
  end

  private

  def compute_normalized_value
    self.normalized_value = self.class.normalize(value)
  end

  def normalized_value_has_minimum_alphanumerics
    alphanumeric_count = normalized_value.scan(/[a-z0-9]/i).size
    return if alphanumeric_count >= 3

    errors.add(:normalized_value, 'doit contenir au moins 3 caractères alphanumériques une fois normalisée')
  end
end
